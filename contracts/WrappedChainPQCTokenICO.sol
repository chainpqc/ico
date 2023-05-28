// SPDX-License-Identifier: MIT

// This contract is designed to manage its ICO.
// The contract uses the OpenZeppelin library for ERC20, Ownable, and SafeMath functionality.
// The contract ensures that only the owner can mint and burn tokens, and it limits the total supply of tokens.
// The ICO has a minimum investment amount, a minimum cap, and a maximum number of tokens that can be sold.
// The price of the tokens increases over time during the ICO.
// The contract also provides functions for the owner to withdraw the raised ether and for users to get a refund if the minimum cap is not reached.
// These features help to protect against hacking attempts and ensure a fair and secure ICO process.

pragma solidity ^0.8.0;

// Importing the ERC20, Ownable, and SafeMath contracts from the OpenZeppelin library
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WrappedChainPQCToken.sol";


// WrappedChainPQCTokenICO is a contract for managing the ICO of the WrappedChainPQCToken
contract WrappedChainPQCTokenICO is Ownable {
    using SafeMath for uint256;

    WrappedChainPQCToken public token;

    // Constants for the ICO
    uint256 public constant MIN_INVESTMENT = 0.1 ether;
    uint256 public constant MIN_CAP = 50 ether;
    uint256 public constant MAX_TOKENS = 115000000000000000000000000; // 115 million tokens with 18 decimal places
    uint256 public constant ICO_DURATION = 180 days;
    uint256 public constant TOKENS_PER_ETH_START = 25000; // 0.00004 ETH per token
    uint256 public constant TOKEN_PRICE_INCREASE_PER_PERIOD = 250; // end price 0.0001 ETH
    uint256 public constant PERIOD_PRICE_INCREASE = 3 days;

    // Variables for tracking the ICO progress
    uint256 public tokensSold;
    uint256 public weiRaised;
    uint256 public startTime;
    bool public icoEnded;

    // Mapping to store the investments made by each address
    mapping(address => uint256) public investments;

    // Events for logging various actions
    event TokensPurchased(address indexed buyer, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event EndICO(string message);

    // Constructor initializes the token contract
    constructor(WrappedChainPQCToken _token) {
        token = _token;
    }

    // startICO function mints the maximum number of tokens and sets the start time of the ICO
    function startICO() public payable {
        require(token.totalSupply() == 0, "Once can mint all coins");
        token.mintWithTransfer(msg.sender, address(this), MAX_TOKENS);
        startTime = block.timestamp;
    }

    // Fallback function to allow users to buy tokens by sending ether directly to the contract
    receive() external payable {
        buyTokens();
    }

    // buyTokens function allows users to buy tokens by sending ether to the contract
    function buyTokens() public payable {
        require(!icoEnded, "ICO has ended.");
        require(block.timestamp < startTime.add(ICO_DURATION), "ICO ended.");
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.1 ETH.");
        uint256 tokens = calculateTokenAmount(msg.value);
        require(tokensSold.add(tokens) <= MAX_TOKENS, "Not enough tokens");

        weiRaised = weiRaised.add(msg.value);
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        token.transfer(msg.sender, tokens);
        tokensSold = tokensSold.add(tokens);

        emit TokensPurchased(msg.sender, tokens);
    }

    // calculateTokenAmount function calculates the number of tokens a user will receive for a given amount of ether
    function calculateTokenAmount(uint256 weiAmount) public view returns (uint256) {
        uint256 elapsedTime = block.timestamp.sub(startTime);
        // Calculate the number of months that have passed since the ICO started
        uint256 monthsPassed = elapsedTime.div(PERIOD_PRICE_INCREASE);
        uint256 tokensPerEth = TOKENS_PER_ETH_START.sub(TOKEN_PRICE_INCREASE_PER_PERIOD.mul(monthsPassed));
        require(tokensPerEth >= 1, "The price of 1 WPQC is higher than 1 ETH");
        // Calculate the number of tokens based on the current number of tokens per ETH
        uint256 tokenAmount = weiAmount.mul(tokensPerEth);
        return tokenAmount;
    }

    // endICO function ends the ICO and burns any remaining tokens
    function endICO() payable public onlyOwner {
        require(!icoEnded, "ICO has already ended.");
        require(block.timestamp >= startTime.add(ICO_DURATION), "ICO has not yet ended.");

        uint256 remainingTokens = token.balanceOf(address(this));
        if (remainingTokens > 0) {
            token.burn(msg.sender, address(this), remainingTokens); // Burning remaining tokens
        }
        icoEnded = true;
        emit EndICO("ICO has ended");
    }

    // withdraw function allows the owner to withdraw the raised ether if the minimum cap is reached
    function withdraw() public payable onlyOwner {
        require(weiRaised >= MIN_CAP, "Minimum value not reached.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    // refund function allows users to get a refund if the ICO has ended and the minimum cap is not reached
    function refund() public {
        require(icoEnded, "ICO has not ended.");
        require(weiRaised < MIN_CAP, "Minimum value reached.");
        uint256 investment = investments[msg.sender];
        require(investment > 0, "No investment found.");
        investments[msg.sender] = 0;
        payable(msg.sender).transfer(investment);
    }
}