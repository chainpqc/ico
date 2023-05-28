// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.0;


contract WrappedChainPQCToken is ERC20 {
    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender, "Only owner can do this");
        _;
    }

    constructor() ERC20("Wrapped ChainPQC Token", "WPQC") {
        owner = msg.sender;
    }

    function mintWithTransfer(address from, address to, uint256 amount) public {
        require(from == owner, "Minting is reserved for owner");
        _mint(from, amount);
        _transfer(from, to, amount);
    }
    function burn(address executor, address tokenOwner, uint256 amount) public {
        require(executor == owner, "Burning is reserved for owner");
        require(msg.sender == tokenOwner, "Only a sender can burn his own tokens");
        _burn(tokenOwner, amount);
    }
}


contract WrappedChainPQCTokenICO is Ownable {
    using SafeMath for uint256;

    WrappedChainPQCToken public token;

    uint256 public constant MIN_INVESTMENT = 0.1 ether;
    uint256 public constant MIN_CAP = 5 ether;
    uint256 public constant MAX_TOKENS = 230000000000000000000000000; // 230 million tokens with 18 decimal places
    uint256 public constant ICO_DURATION = 180 days;
    uint256 public constant TOKENS_PER_ETH_START = 25000; // 0.00004 ETH per token
    uint256 public constant TOKENS_PER_ETH_END = 5000; // 0.0002 ETH per token
    uint256 public constant TOKEN_PRICE_INCREASE_PER_PERIOD = 400;
    uint256 public constant PERIOD_PRICE_INCREASE = 3 days;

    uint256 public tokensSold;
    uint256 public weiRaised;
    uint256 public startTime;
    bool public icoEnded;

    mapping(address => uint256) public investments;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event LogUint256(uint256 message);
    event LogAddress(address message);
    event Log(string message);
    event EndICO(string message);

    constructor(WrappedChainPQCToken _token) {
        token = _token;
    }

    function startICO() public payable {
        require(token.totalSupply() == 0, "Once can mint all coins");
        token.mintWithTransfer(msg.sender, address(this), MAX_TOKENS);
        startTime = block.timestamp;
    }

    receive() external payable {
        buyTokens();
    }

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

    function withdraw() public payable onlyOwner {
        require(weiRaised >= MIN_CAP, "Minimum value not reached.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
    function refund() public {
        require(icoEnded, "ICO has not ended.");
        require(weiRaised < MIN_CAP, "Minimum value reached.");
        uint256 investment = investments[msg.sender];
        require(investment > 0, "No investment found.");
        investments[msg.sender] = 0;
        payable(msg.sender).transfer(investment);
    }
}