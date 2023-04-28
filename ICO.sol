// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ERC20tokens.sol";

contract ICOArianToken{

    struct InvestprDetail{
        address investor;
        uint    amount;
    }

    InvestprDetail[] public totalInvestors;

    mapping(address => bool) public isInvstors;

    address public tokenAddress;
    address public Admin;
    uint public totalAmount;
    uint public ICOAmount;

    bool public isReleaseTokens;
    uint public deadline;

    uint public minPurchase;
    uint public maxPurchase;
    uint public price; // token to eth ratio

    modifier onlyAdmin(){
        require(msg.sender == Admin, "your not admin");
        _;
    }

    modifier onlyNewInvestor(){
        require(isInvstors[msg.sender] == false, "your not investor");
        _;
    }

    modifier onlyAfterStart(){
        require(deadline >= 0, "ICO not started yet");
        _;
    }

    modifier deadlineReached(){
        require(block.timestamp < deadline , "ICO finished");
        _;
    }

    modifier availableToken(){
        require(ICOAmount > 0 , "ICO tokens not sufficient");
        _;
    }

    modifier onlyAfterRelease(){
        require(isReleaseTokens , "token not released yet");
        _;
    }

    modifier OnlyEOA{
        require(isContract(msg.sender) == false , "shoudl only be a EOA");
        _;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
        size := extcodesize(_addr)
        }
        return (size > 0);
    }


    constructor(string memory _name , string memory _symbol , uint _totalAmount){

        require(_totalAmount > 0 , "not a number");

        Admin = msg.sender;

        tokenAddress = address (new ArianErc20(_name ,_symbol ,_totalAmount));

        ICOAmount = _totalAmount / 10;
    }

    function startICO(uint _minPurchase,uint _maxPurchase,uint duration ,uint _price)public onlyAdmin deadlineReached{

        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        price = _price;
        deadline = block.timestamp + duration;
    }

    function buyTokens()external payable onlyAfterStart onlyNewInvestor OnlyEOA availableToken{

        require(msg.value >= minPurchase && msg.value <= maxPurchase , "value not allowed");

        uint quantity = price * msg.value;

        require(quantity <= ICOAmount , "not enough tokens");

        InvestprDetail memory investprDetail = InvestprDetail(msg.sender,quantity);

        totalInvestors.push(investprDetail);

        isInvstors[msg.sender] = true;

    }

    function releaseTokens()external onlyAdmin onlyAfterStart{
        isReleaseTokens = true;

        for(uint i = 0 ; i < totalInvestors.length ; i++){
            ArianErc20(tokenAddress).transfer(totalInvestors[i].investor,totalInvestors[i].amount);
        }

    }

    function withdrawEth(address payable to)external onlyAdmin deadlineReached onlyAfterRelease{
        to.transfer(address(this).balance);
    }

    function timeRemainToRelease()external view returns(uint){
        return deadline - block.timestamp;
    }


} 