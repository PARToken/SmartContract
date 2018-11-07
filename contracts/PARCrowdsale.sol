pragma solidity ^0.4.24;

import "./PARToken.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/**
 * @title PARCrowdsale
 * @dev Extension of MintedCrowdsale to handle to crowdsale of the PARToken
 * @dev the rate logic is changed, now the rate variable is the exchange rate from USD to ethereum
 * @dev this is done because the price per token during the crowdsale stage is USD based
 * 
 */
contract PARCrowdsale is FinalizableCrowdsale, Pausable 
{
	using SafeMath for uint256;
	
	uint256 private constant p100        = 100 * 10**18;
	uint256 private constant p10         = 10  * 10**18;
	uint256 private constant precision   = 10**6;
	
	// Setted at deploy time for debug purpose
	uint256 private ICO_START;   	// 1539302400 => 2018-11-07 @  2:00am (UTC)
	uint256 private ICO_STAGE_2; 	// 1542326400 => 2018-11-16 @ 12:00am (UTC)
	uint256 private ICO_STAGE_3; 	// 1546300800 => 2019-01-01 @ 12:00am (UTC)
	uint256 private ICO_END;     	// 1551398400 => 2019-03-01 @ 12:00am (UTC)
	
	uint256 public constant TOKEN_CAP = 97.0  * 10**6 * 10**18; // 97,00m PARs total supply
	
	address public operator;		// Address of the operator of the Contract for the periodic exchange rate update
	address public admin1;			// Address of the admin #1
	address public admin2;			// Address of the admin #2
	address public funds;			// Address to collet the funds
	
	uint256 public soldToken  = 0;	// Amount of token sold
	uint256 public bonusToken = 0;	// Amount of bonus token provided

	uint256 private tmpSold   = 0;	// temp variable to calculate the token sold during the purchase
	uint256 private tmpBonus  = 0;	// temp variable to calculate the bonus provided during the purchase
	
	enum stage { notStarted, stage1, stage2, stage3, closed }

	uint256 public constant tokenPrice   = 1 * 10**18;	// 1$ x token
	
	uint256 public constant stage1Bonus  = 30 * 10**18;
	uint256 public constant stage2Bonus  = 20 * 10**18;
	uint256 public constant stage3Bonus  = 10 * 10**18;
	
	//event Debug( string msgText, uint256 msgVal);
	event TokenSent(address wallet, uint256 amount, uint256 bonus);
	event fundsUpdated(address oldWallet, address newWallet);
	event admin1Updated(address oldWallet, address newWallet);
	event admin2Updated(address oldWallet, address newWallet);
	event OperatorUpdated(address oldOperator, address newOperator);
	event RateUpdated(uint256 oldRate, uint256 newRate);
	
	/**
	 * @dev Throws if called by any account other than the owner or operator.
	 */
	modifier onlyOperator() {
		require( (msg.sender == owner) || (msg.sender == admin1) || (msg.sender == admin2) || (msg.sender == operator) );
		_;
	}

	modifier onlyAdmins() {
		require( (msg.sender == owner) || (msg.sender == admin1) || (msg.sender == admin2) );
		_;
	}
	
	/**
	 * @param _rate       Starting exchange rate €uro/Ethereum
	 * @param _icoStart   Timestamp of the ICO Start
	 * @param _icoStage2  Timestamp of the ICO Stage 2 Start
	 * @param _icoStage3  Timestamp of the ICO Stage 3 Start
	 * @param _icoEnd     Timestamp of the ICO End
	 * @param _operator   Address of the operator of the Contract for the periodic exchange rate update
	 * @param _admin1     Address of the admin #1
	 * @param _admin2     Address of the admin #2
	 * @param _funds      Address to collet the funds
	 */
	constructor(
			uint256 _rate,
			uint256 _icoStart,
			uint256 _icoStage2,
			uint256 _icoStage3,
			uint256 _icoEnd,
			address _operator,
			address _admin1,
			address _admin2,
			address _funds
	) 
		public
		Crowdsale(_rate, _funds, ERC20( new PARToken(TOKEN_CAP) ) )
		TimedCrowdsale(_icoStart, _icoEnd)
	{
		require(_operator   != address(0));
		require(_admin1     != address(0));
		require(_admin2     != address(0));
		require(_funds  	!= address(0));

		require(_funds  	!= _operator);
		
		operator    = _operator;
		admin1		= _admin1;
		admin2		= _admin2;
		funds   	= _funds;

		ICO_START   = _icoStart;
		ICO_STAGE_2 = _icoStage2;
		ICO_STAGE_3 = _icoStage3;
		ICO_END     = _icoEnd;
		
		// Token Preallocation
		token.safeTransfer( 0xc24f51aE67385fcad0ea0724096a9f12654F7074, 19.4   * 10**6 * 10**18 ); // 19,400m PARs
		token.safeTransfer( 0xF94F1F227A82A1821D027A933d8d625896590EC1,  4.85  * 10**6 * 10**18 ); //  4,850m PARs
		token.safeTransfer( 0x0E060E0afB1bfA0ef1A6De68DA17EA7DBa74f927,  9.7   * 10**6 * 10**18 ); //  9,700m PARs
		token.safeTransfer( 0xD37cB5d2D35149E23C37eC41FA55DdBe1D988F77,  4.85  * 10**6 * 10**18 ); //  4,850m PARs
		token.safeTransfer( 0xc57502Df76c6e9BDf6aede62aa81F13068641061,  2.91  * 10**6 * 10**18 ); //  2,910m PARs
		token.safeTransfer( 0xE95EAf7e239899E4E42d003E55b54F893eB2D71a,  3.395 * 10**6 * 10**18 ); //  3,395m PARs
		token.safeTransfer( 0xb3934Eb07B6CBA08e0f7Db88AF4Da60FcA594168,  3.395 * 10**6 * 10**18 ); //  3,395m PARs
	}

	/**
	 * @dev add the condition whenNotPaused to the base validation of an incoming purchase
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
		internal 
		whenNotPaused
	{
		/*
		 *		Calculate how many tokens I'm purchasing
		 */
		tmpSold  = _weiAmount.mul( rate ).div( tokenPrice );
		
		/*
		 *		Minimum 10 tokens 
		 */
		require( tmpSold >= 10 * 10**18);
		
		/*
		 *		During the stage one I can't sold more then 57500 token
		 */
		if( _currentStage() == stage.stage1 )
		{
			require( soldToken.add( tmpSold ) <= 57500 * 10**18 );
		}

		/*
		 *		Calculate the bonus token for the current stage
		 */
		tmpBonus = tmpSold.mul(precision).div(p100).mul( _currentBonus(_currentStage()) ).div(precision);

		/*
		 *		I have sufficient Token ?
		 */
		require( token.balanceOf(this) >= tmpSold.add(tmpBonus) );
		
		super._preValidatePurchase(_beneficiary, _weiAmount);
	}

	/**
	 * @dev Return the current stage of the crowdsale
	 */
	function _currentStage()
		internal
		view
		returns (stage)
	{
		if( now >= ICO_END )     { return stage.closed; }
		if( now >= ICO_STAGE_3 ) { return stage.stage3; }
		if( now >= ICO_STAGE_2 ) { return stage.stage2; }
		if( now >= ICO_START )   { return stage.stage1; }

		return stage.notStarted;
	}
	
	/**
	 * @dev Return the current bonus percentage
	 */
	function _currentBonus(stage _stage)
		internal
		view
		returns (uint256)
	{
		if( _stage == stage.stage3 ) { return stage3Bonus; }
		if( _stage == stage.stage2 ) { return stage2Bonus; }
		if( _stage == stage.stage1 ) { return stage1Bonus; }

		return 0;
	}
	
	/**
	 * @dev Overriding this I can handle the logic of the crowdsale
	 * @param _weiAmount Value in wei to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount)
		internal
		view
		returns (uint256) 
	{
		/**
		 * Formula = ( ( wei * ethPriceInEuro / tokenPriceInEuro ) + %bonus )
		 */

		uint256 _t = _weiAmount.mul( rate ).div( tokenPrice );
		
		return _t.add( _t.mul(precision).div(p100).mul( _currentBonus(_currentStage()) ).div(precision) );
	}
	
	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds() 
		internal 
	{
		funds.transfer(msg.value);
	}
	
	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount)
		internal
	{
		soldToken  = soldToken.add( tmpSold );
		bonusToken = bonusToken.add( tmpBonus );
		
		super._postValidatePurchase(_beneficiary, _weiAmount);
	}
	
	/**
	 * @dev Finalize the Crowdsale and send the remain token to the owner
	 */
	function finalization() 
		internal 
	{
		uint256 _avail = token.balanceOf(this);
		
		if( _avail > 0 )
		{
			token.safeTransfer( funds, _avail );
		}
		
		super.finalization();
	}
	
	/**
	 * @dev Send Token to the customer that have purchased the token via alternative method (Wire transfer, Credit card, Bitcoin, and so on)
	 * @param _wallet destination address
	 * @param _amount amount of the purchased token
	 * @param _bonus amount of the bonus token for this purchase
	 */
	function sendToken( address _wallet, uint256 _amount, uint256 _bonus ) 
		external 
		onlyAdmins 
	{ 
		require(_wallet != address(0)); 
		require(_amount > 0);
		require(_bonus > 0);
		
		/*
		 *		During the stage one I can't sold more then 57500 token
		 */
		if( _currentStage() == stage.stage1 )
		{
			require( soldToken.add( _amount ) <= 57500 );
		}

		/*
		 *		have I sufficient Token ?
		 */
		require( token.balanceOf(this) >= _amount.add(_bonus) );
		
		token.safeTransfer( _wallet, _amount.add(_bonus) );

		soldToken  = soldToken.add( _amount );
		bonusToken = bonusToken.add( _bonus );

		emit TokenSent(_wallet, _amount, _bonus);
	}
	
	// ------------------------------------------------------
	// Owner utility to update wallets, operator, rate, etc
	// ------------------------------------------------------

	/**
	 * @dev Update the funds wallet address
	 * @param _wallet new wallet address
	 */
	function updateFunds( address _wallet ) 
		external 
		onlyAdmins
	{ 
		require(_wallet != address(0)); 
		require(_wallet != wallet); 
		
		emit fundsUpdated(funds, _wallet);
		funds = _wallet; 
	}
	
	/**
	 * @dev Update the admin #1 wallet address
	 * @param _wallet new wallet address
	 */
	function updateAdmin1( address _wallet ) 
		external 
		onlyOwner
	{ 
		require(_wallet != address(0)); 
		require(_wallet != wallet); 
		
		emit admin1Updated(admin1, _wallet);
		admin1 = _wallet; 
	}
	
	/**
	 * @dev Update the admin #2 wallet address
	 * @param _wallet new wallet address
	 */
	function updateAdmin2( address _wallet ) 
		external 
		onlyOwner
	{ 
		require(_wallet != address(0)); 
		require(_wallet != wallet); 
		
		emit admin2Updated(admin2, _wallet);
		admin2 = _wallet; 
	}
	
	/**
	 * @dev Update the operator address
	 * @param _operator new operator address
	 */
	function updateOperator( address _operator ) 
		external 
		onlyAdmins
	{ 
		require(_operator != address(0)); 
		require(_operator != operator); 
		
		emit OperatorUpdated(operator, _operator);
		operator = _operator; 
	}
	
	/**
	 * @dev this function is periodically called from the owner's backend to update the exchange rate from €uro to Ethereum
	 * @param _rate new rate
	 */
	function updateRate( uint256 _rate ) 
		external 
		whenNotPaused 
		onlyOperator
	{ 
		require(_rate  > 0); 
		
		emit RateUpdated(rate, _rate); 
		rate = _rate; 
	}
}
