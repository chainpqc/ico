// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
        _burn(tokenOwner, amount);
    }
}