pragma solidity ^0.4.12;

import './zeppelin/token/MintableToken.sol';
import './zeppelin/ownership/HasNoContracts.sol';
import './zeppelin/ownership/HasNoTokens.sol';
import './BurnableToken.sol';

/**
 * @title MatreXa Token
 */
contract MatreXaToken is BurnableToken, MintableToken, HasNoContracts, HasNoTokens { //MintableToken is StandardToken, Ownable
    using SafeMath for uint256;

    string public name = "MatreXa";
    string public symbol = "MTRX";
    uint256 public decimals = 18;

    uint256 public allowTransferTimestamp = 0;

    modifier canTransfer() {
        require(mintingFinished);
        require(now > allowTransferTimestamp);
        _;
    }

    function setAllowTransferTimestamp(uint256 _allowTransferTimestamp) onlyOwner {
        require(allowTransferTimestamp == 0);
        allowTransferTimestamp = _allowTransferTimestamp;
    }
    
    function transfer(address _to, uint256 _value) canTransfer returns (bool) {
        BurnableToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer returns (bool) {
        BurnableToken.transferFrom(_from, _to, _value);
    }

}
