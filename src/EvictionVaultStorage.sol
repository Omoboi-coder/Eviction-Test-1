// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IEvictionVault.sol";

abstract contract EvictionVaultStorage {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;
    uint256 public txCount;

    mapping(address => uint256) public balances;
    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;
    mapping(bytes32 => bool) public usedHashes;

    uint256 public constant TIMELOCK_DURATION = 1 hours;
    uint256 public totalVaultValue;
    bool public paused;

    modifier onlyMultisig() {
        require(msg.sender == address(this), "EvictionVault: only multisig allowed");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "EvictionVault: not an owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "EvictionVault: contract is paused");
        _;
    }
}
