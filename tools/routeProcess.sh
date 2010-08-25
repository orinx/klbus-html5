#!/bin/bash

# route processor - medicalwei

targetDir="../stops"

## variables end

# remove $targetDir
rm -rf $targetDir

# create folders needed
mkdir -p $targetDir
mkdir -p $targetDir/routes
mkdir -p $targetDir/routes.1.tmp
mkdir -p $targetDir/routes.2.tmp

# go to targetDir
cd ${targetDir}

# fetch all routes
allRoutes=`wget -O - "http://ebus.klcba.gov.tw/KLBusWeb/getAllRoute.jsp" | iconv -f big5 -t utf-8 | sed -e 's/&/\n/g' | sed -e 's/^\([0-9]*\).*$/\1/'`


# begin routesName
echo '"routes": {' > "routesName.json.1.tmp"




for i in $allRoutes
do

	routeDetail=`wget -O - "http://ebus.klcba.gov.tw/KLBusWeb/getRouteDetailByID?rgid=$i" | iconv -f big5 -t utf-8 | sed -e 's/MainRoute.*$//g' | sed -e 's/&/\n/g'`

	for eachRoute in $routeDetail
	do

		routeNumber=`echo $eachRoute | sed -e 's/^\([0-9]*\).*$/\1/g'`
		routeName=`echo $eachRoute | sed -e 's/^[0-9]*_\(.*\)=.*$/\1/g'`
		routeStops=`echo $eachRoute | sed -e 's/^.*=//g' | sed -e 's/;/\n/g' | sed -n '/:.*:.*:/p'`

		# collect routeNumber and routeName information 
		echo "\"${routeNumber}\":\"${routeName}\"," >> "routesName.json.1.tmp"

		for routeStop in $routeStops
		do
			routeStopNumber=`echo $routeStop | sed -e 's/^\([0-9]*\).*$/\1/g'`

			# collect stops info 
			echo $routeStop >> "stopsInfo.1.tmp"

			# collect route number and detailed route number 
			echo "$i" >> "routes.1.tmp/${routeStopNumber}"
			echo "$routeNumber" >> "routes.2.tmp/${routeStopNumber}"
		done

	done

done




#closing routesName
cat "routesName.json.1.tmp" | sed -e '$s/,$/\}/' > "routesName.json.2.tmp"




# unique stopsInfo
cat "stopsInfo.1.tmp" | sort -n | uniq > "stopsInfo.2.tmp"




# jsonize stopsInfo

echo '"stops": [' > "stopsInfo.json.1.tmp"

for routeStop in `cat "stopsInfo.2.tmp"`
do
	echo $routeStop | sed -e 's/^\(.*\):\(.*\):\(.*\):\(.*\)$/{\"id\":\1,\"name\":\"\2\",\"lon\":\3,\"lat\":\4},/' >> "stopsInfo.json.1.tmp"
done

cat "stopsInfo.json.1.tmp" | sed -e '$s/,$/\]/' > "stopsInfo.json.2.tmp"




# combine routes information into a json file for each stop

for f in `ls routes.1.tmp`
do
	echo '{"routes": [' > "routes/$f.json"
	cat "routes.1.tmp/$f" | sort -n | uniq | sed -e 's/^\(.*\)$/\"\1\",/' | sed -e '$s/,$/],/' >> "routes/$f.json"
	echo '"detailedRoutes": [' >> "routes/$f.json"
	cat "routes.2.tmp/$f" | sort -n | uniq | sed -e 's/^\(.*\)$/\"\1\",/' | sed -e '$s/,$/]}/' >> "routes/$f.json"
done




# combine routesName and stopsInfo into a json file
echo "{"`cat "routesName.json.2.tmp"`","`cat "stopsInfo.json.2.tmp"`"}" > "info.json"


# remove all temp file
rm *tmp -rf
