pragma solidity ^0.4.12;

import './zeppelin/token/MintableToken.sol';
import './zeppelin/ownership/HasNoContracts.sol';
import './zeppelin/ownership/HasNoTokens.sol';
import './BurnableToken.sol';

/**
 * @title MatreXaToken
 */
contract MatreXaToken is BurnableToken, MintableToken, HasNoContracts, HasNoTokens { //MintableToken is StandardToken, Ownable
    using SafeMath for uint256;

    string public name = "MatreXa";
    string public symbol = "MTRX";
    uint256 public decimals = 18;

}
