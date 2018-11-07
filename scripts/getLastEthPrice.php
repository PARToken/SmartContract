<?php
	$lastPrice = json_decode( file_get_contents( 'https://api.coinmarketcap.com/v1/ticker/ethereum/' ), TRUE );
	if( $lastPrice === FALSE )
	{
	} else {
		$line = time() . ',' . $lastPrice[0]['price_usd'] . "\n";
		file_put_contents( 'ethprice.dat', $line, FILE_APPEND );
	}
?>
