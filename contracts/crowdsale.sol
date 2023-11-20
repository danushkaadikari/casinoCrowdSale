// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdsale {
    IERC20 public myToken;
    IERC20 public usdtToken;

    address public owner;
    uint256 public currentRound = 0;
    uint256 public constant totalRounds = 4;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256) public amountPurchased;
    uint256 public globalPurchaseLimit;

    struct Round {
        uint256 startTime;
        uint256 endTime;
        uint256 tokenPrice;
    }

    // Events
    event RoundSet(uint256 indexed round, uint256 startTime, uint256 endTime, uint256 tokenPrice);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event RoundAdvanced(uint256 newRound);
    event USDTWithdrawn(uint256 amount);
    event GlobalPurchaseLimitUpdated(uint256 newLimit);

    constructor(address _myToken, address _usdtToken, uint256 _globalPurchaseLimit) {
        myToken = IERC20(_myToken);
        usdtToken = IERC20(_usdtToken);
        owner = msg.sender;
        globalPurchaseLimit = _globalPurchaseLimit;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setRound(uint256 round, uint256 startTime, uint256 endTime, uint256 tokenPrice) external onlyOwner {
        require(round < totalRounds, "Invalid round");
        rounds[round] = Round(startTime, endTime, tokenPrice);
        emit RoundSet(round, startTime, endTime, tokenPrice);
    }

    function buyTokens(uint256 amount) external {
        require(currentRound < totalRounds, "Crowdsale ended");
        Round memory round = rounds[currentRound];
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Round not active");
        require(amountPurchased[msg.sender] + amount <= globalPurchaseLimit, "Global purchase limit exceeded");

        uint256 cost = amount * round.tokenPrice;
        require(usdtToken.transferFrom(msg.sender, address(this), cost), "USDT transfer failed");
        amountPurchased[msg.sender] += amount;

        myToken.transfer(msg.sender, amount);
        emit TokensPurchased(msg.sender, amount);
    }

    function advanceRound() external onlyOwner {
        require(currentRound < totalRounds, "All rounds completed");
        currentRound++;
        emit RoundAdvanced(currentRound);
    }

    function withdrawUSDT(uint256 amount) external onlyOwner {
        require(usdtToken.transfer(msg.sender, amount), "USDT transfer failed");
        emit USDTWithdrawn(amount);
    }

    function setGlobalPurchaseLimit(uint256 limit) external onlyOwner {
        globalPurchaseLimit = limit;
        emit GlobalPurchaseLimitUpdated(limit);
    }
}
