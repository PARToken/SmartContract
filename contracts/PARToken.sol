pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract PARToken is StandardToken
{
	string  public constant name     = "PAR Token";
	string  public constant symbol   = "PAR";
	uint256 public constant decimals = 18;

	constructor(uint256 _cap) public 
	{
		totalSupply_         = _cap;
		balances[msg.sender] = _cap;
	}
}
