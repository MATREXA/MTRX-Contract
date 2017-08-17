pragma solidity ^0.4.12;

import './zeppelin/math/SafeMath.sol';
import './zeppelin/ownership/Ownable.sol';
import './zeppelin/ownership/HasNoContracts.sol';
import './zeppelin/ownership/HasNoTokens.sol';
import './MatreXaToken.sol';


contract MatreXaCrowdsale is Ownable, HasNoContracts, HasNoTokens {
    using SafeMath for uint256;

    //use https://www.myetherwallet.com/helpers.html for simple coversion to/from wei
    uint256 constant public MAX_GAS_PRICE  = 50000000000 wei;    //Maximum gas price for contribution transactions
    uint256 public goal;                                         //Amount of ether (in wei) to receive for crowdsale to be successful

    MatreXaToken public mtrx;

    uint256 public availableSupply;     //tokens left to sale
    uint256 public startTimestamp;      //start crowdsale timestamp
    uint256 public endTimestamp;        //after this timestamp no contributions will be accepted and if minimum cap not reached refunds may be claimed
    uint256 public totalCollected;      //total amount of collected funds (in ethereum wei)
    uint256[] public periods;           //periods of crowdsale with different prices
    uint256[] public prices;            //prices of each crowdsale periods
    bool public finalized;              //crowdsale is finalized
    
    mapping(address => uint256) contributions; //amount of ether (in wei)received from a contributor

    event LogSale(address indexed to, uint256 eth, uint256 tokens);

    /**
     * @dev Asserts crowdsale goal is reached
     */
    modifier goalReached(){
        require(totalCollected >= goal);
        _;
    }

    /**
     * @dev Asserts crowdsale is finished, but goal not reached 
     */
    modifier crowdsaleFailed(){
        require(totalCollected < goal);
        require(now > endTimestamp);
        _;
    }

    /**
     * Throws if crowdsale is not running: not started, ended or max cap reached
     */
    modifier crowdsaleIsRunning(){
        // require(now > startTimestamp);
        // require(now <= endTimestamp);
        // require(availableSupply > 0);
        // require(!finalized);
        require(crowdsaleRunning());
        _;
    }

    /**
    * verifies that the gas price is lower than 50 gwei
    */
    modifier validGasPrice() {
        assert(tx.gasprice <= MAX_GAS_PRICE);
        _;
    }

    /**
     * @dev MatreXa Crowdsale Contract
     * @param _startTimestamp Start crowdsale timestamp
     * @param _periods Array of timestamps when a corresponding price is no longer valid. Last timestamp is the last date of ICO
     * @param _prices Array of prices (how many token units one will receive per wei) corrsponding to thresholds.
     * @param _goal Amount of ether (in wei) to receive for crowdsale to be successful
     * @param _ownerTokens Amount of MTRX tokens (in wei) minted to owner
     * @param _availableSupply Amount of MTRX tokens (in wei) to distribute during ICO
     */
    function MatreXaCrowdsale(
        uint256 _startTimestamp, 
        uint256[] _periods,
        uint256[] _prices, 
        uint256 _goal,
        uint256 _ownerTokens,
        uint256 _availableSupply
    ) {

        require(_periods.length > 0);                   //There should be at least one period
        require(_startTimestamp < _periods[0]);         //Start should be before first period end
        require(_prices.length == _periods.length);     //Each period should have corresponding price

        startTimestamp = _startTimestamp;
        endTimestamp = _periods[_periods.length - 1];
        periods = _periods;
        prices = _prices;

        goal = _goal;
        availableSupply = _availableSupply;
        
        uint256 reachableCap = availableSupply.mul(_prices[0]);   //find how much ether can be collected in first period
        require(reachableCap > goal);           //Check if it is possible to reach minimumCap (not accurate check, but it's ok) 

        mtrx = new MatreXaToken();
        mtrx.mint(owner, _ownerTokens);
    }

    /**
    * @dev Calculates current price rate (how many MTRX you get for 1 ETH)
    * @return calculated price or zero if crodsale not started or finished
    */
    function currentPrice() constant public returns(uint256) {
        if( (now < startTimestamp) || finalized) return 0;
        for(uint i=0; i < periods.length; i++){
            if(now < periods[i]){
                return prices[i];
            }
        }
        return 0;
    }
    /**
    * @dev Shows if crowdsale is running
    */ 
    function crowdsaleRunning() constant public returns(bool){
        return  (now > startTimestamp) &&  (now <= endTimestamp) && (availableSupply > 0) && !finalized;
    }
    /**
    * @dev Buy MatreXa tokens
    */
    function() payable validGasPrice crowdsaleIsRunning {
        require(msg.value > 0);
        uint256 price = currentPrice();
        assert(price > 0);
        uint256 tokens = price.mul(msg.value);
        assert(tokens > 0);
        require(availableSupply - tokens >= 0);

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        totalCollected = totalCollected.add(msg.value);
        availableSupply = availableSupply.sub(tokens);
        mtrx.mint(msg.sender, tokens);
        LogSale(msg.sender, msg.value, tokens);
    } 

    /**
    * @dev Sends all contributed ether back if minimum cap is not reached by the end of crowdsale
    */
    function claimRefund() public crowdsaleFailed {
        require(contributions[msg.sender] > 0);

        uint256 refund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        msg.sender.transfer(refund);
    }

    /**
    * @dev Sends collected funds to owner
    * May be executed only if goal reached and no refunds are possible
    */
    function withdrawFunds(uint256 amount) public onlyOwner goalReached {
        msg.sender.transfer(amount);
    }

    /**
    * @dev Finalizes ICO when one of conditions met:
    * - end time reached OR
    * - no more tokens available (cap reached) OR
    * - message sent by owner
    */
    function finalizeCrowdfunding() public {
        require ( (now > endTimestamp) || (availableSupply == 0) || (msg.sender == owner) );
        finalized = mtrx.finishMinting();
        mtrx.transferOwnership(owner);
    } 

}