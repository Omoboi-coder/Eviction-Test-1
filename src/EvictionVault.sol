// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";

contract EvictionVault is Vault {
    
    constructor(address[] memory _owners, uint256 _threshold) payable {
        require(_owners.length > 0, "no owners");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");
        
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "Zero address owner");
            require(!isOwner[o], "Double owner");
            isOwner[o] = true;
            owners.push(o);
        }
        totalVaultValue = msg.value;
    }

    // Fixed the receive() uses tx.origin to msg.sender
    receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
