<?php
	if ($argc < 4 )
	{
		echo "missing parameter\n\nusage:\n\t".$argv[0]." [input.sol] [output.js] [output.html]";
		die;
	}
	
	$inputfile = $argv[1];
	$outputjs = $argv[2];
	$outputhtml = $argv[3];
	
	$json = json_decode( file_get_contents( $inputfile ), TRUE );

	//var_dump( $json['abi'] );
	
	foreach( $json['abi'] as $k => $f )
	{
		$n = (isset($f['name']) ? $f['name'] : "");
		$t = (isset($f['type']) ? $f['type'] : "");
		$s = (isset($f['stateMutability']) ? $f['stateMutability'] : "n/a");
		$p = (isset($f['payable']) ? $f['payable'] : false );
		$c = (isset($f['constant']) ? $f['constant'] : false );
		echo sprintf("%-32s %-15s %-15s %-5s %-5s\n",
			$n,
			$t,
			$s,
			($p ? "true" : "false" ),
			($c ? "true" : "false" ) );
	}
?>
