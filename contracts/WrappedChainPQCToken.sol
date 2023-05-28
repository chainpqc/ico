// SPDX-License-Identifier: MIT

// This contract has been created for the purpose of creating a wrapped token (WPQC).
// WPQC will be exchangeable 1 to 1 with the PQC coin. The PQC coin is the native coin in the ChainPQC network.
// The exchange will also be provided by a decentralized bridge built into the ChainPQC blockchain.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// WrappedChainPQCToken is an ERC20 token contract
contract WrappedChainPQCToken is ERC20 {
    address public owner;

    // onlyOwner modifier ensures that only the owner of the contract can execute the function
    modifier onlyOwner {
        require(owner == msg.sender, "Only owner can do this");
        _;
    }

    // Constructor sets the owner of the contract and initializes the ERC20 token with a name and symbol
    constructor() ERC20("Wrapped ChainPQC Token", "WPQC") {
        owner = msg.sender;
    }

    // mintWithTransfer function allows the owner to mint tokens and transfer them to a specified address
    function mintWithTransfer(address from, address to, uint256 amount) public {
        require(from == owner, "Minting is reserved for owner");
        _mint(from, amount);
        _transfer(from, to, amount);
    }

    // burn function allows the owner to burn tokens from a specified address
    function burn(address executor, address tokenOwner, uint256 amount) public {
        require(executor == owner, "Burning is reserved for owner");
        require(msg.sender == tokenOwner, "Only a sender can burn his own tokens");
        _burn(tokenOwner, amount);
    }
}