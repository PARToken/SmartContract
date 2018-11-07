const PARConfig    = require('../PARConfig.js');
const PARToken     = artifacts.require('./PARToken.sol');
const PARCrowdsale = artifacts.require('./PARCrowdsale.sol');

module.exports = function(deployer, network, accounts) 
{
	const rate = new web3.BigNumber(210.7264 * 10**18);

	var icoStart;
	var icoStage2;
	var icoStage3;
	var icoEnd;
	
	if( network == 'development' )
	{
		icoStart  = Math.floor(Date.now() / 1000) + 15;
		icoStage2 = icoStart + 600;
		icoStage3 = icoStage2 + 600;
		icoEnd    = icoStage3 + 600;
	}
	
	if( network == 'ropsten' )
	{
		icoStart  = Math.floor(Date.now() / 1000) + 120;
		icoStage2 = 1542326400; // 2018-11-16 @ 12:00am (UTC)
		icoStage3 = 1546300800; // 2019-01-01 @ 12:00am (UTC)
		icoEnd    = 1551398400; // 2019-03-01 @ 12:00am (UTC)
	}               
	
	if( network == 'mainnet' )
	{
		icoStart  = Math.floor(Date.now() / 1000) + 900;
		icoStage2 = 1542326400; // 2018-11-16 @ 12:00am (UTC)
		icoStage3 = 1546300800; // 2019-01-01 @ 12:00am (UTC)
		icoEnd    = 1551398400; // 2019-03-01 @ 12:00am (UTC)
	}
	
	const operator  = PARConfig.networks[network].operator.address;
	const adm1      = PARConfig.networks[network].adm1.address;
	const adm2      = PARConfig.networks[network].adm2.address;
	const funds     = PARConfig.networks[network].funds.address;

	return deployer.deploy( PARCrowdsale, rate, icoStart, icoStage2, icoStage3, icoEnd, operator, adm1, adm2, funds );
	
}
