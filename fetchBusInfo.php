<?php

header("Expires: 0");
header("Cache-Control: must-revalidate, post-check=0, pre-check=0");

$routeId=(int) $_GET["id"];
$stopId=(int) $_GET["stopId"];
$handle = fopen("http://ebus.klcba.gov.tw/KLBusWeb/getBusPosAndExpTimeByRoute?rgid=$routeId", "r");
$content = explode("&", iconv('big5', 'utf-8', stream_get_contents($handle)));
fclose($handle);
$a0=array();

foreach ($content as $line){
	if(preg_match("/^tim/", $line)){
		$kv=explode("=", $line);
		$key=substr($kv[0], 3);
		if($key!=$stopId) continue;
		$value=explode(";", $kv[1]);
		

		$a1=array();

		foreach ($value as $route){
			$kv2=explode(":", $route);
			$routeid=$kv2[0];
			$time=$kv2[1];

			array_push($a1, "\"$routeid\":$time");
		}
		$j1=implode(",", $a1);

		array_push($a0, '"'.$key.'":{'.$j1.'}');
	}

}

echo "{\"id\":${routeId},".implode(",", $a0)."}";

?>
