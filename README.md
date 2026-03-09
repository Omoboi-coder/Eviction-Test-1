# Eviction Vault - Refactored and Secured

## Overview
This is the refactored and secured version of the `EvictionVault` smart contract. The original single-file contract has been broken down into a modular structure, and all critical security vulnerabilities have been fixed.

## Current State of the Contract
The contract is now modularized to separate storage, multi-signature consensus, and vault operations. The new structure is as follows:
- **`IEvictionVault.sol`**: Contains the shared `Transaction` struct and all interface definitions.
- **`EvictionVaultStorage.sol`**: Holds all state variables and access control modifiers to prevent storage collisions.
- **`MultiSig.sol`**: Contains the required logic for submitting, confirming, and executing multi-signature transactions.
- **`Vault.sol`**: Handles all core vault operations (deposits, withdrawals, claims, etc.).
- **`EvictionVault.sol`**: The main deployable contract that inherits from the logic modules.

## Implemented Fixes
The following critical vulnerabilities were identified and fixed:

1. **`setMerkleRoot` Callable by Anyone**: Added the `onlyMultisig` modifier so only the contract itself (via a passed multi-sig vote) can change the root.
2. **`emergencyWithdrawAll` Public Drain**: Added the `onlyMultisig` modifier to restrict this function to the multi-signature group, preventing public exploitation.
3. **`pause`/`unpause` Single Owner Control**: Changed from `onlyOwner` to `onlyMultisig` so pausing the vault requires group consensus rather than one person's decision.
4. **`receive()` Uses `tx.origin`**: Changed `tx.origin` to `msg.sender` to prevent potential phishing attacks from malicious smart contracts.
5. **`withdraw` & `claim` Uses `.transfer`**: Replaced `.transfer` (which has a strict 2300 gas limit) with `.call{value: amount}("")` to ensure compatibility and prevent failed transfers.
6. **Timelock Execution Bypass**: Fixed the `submitTransaction` logic so that if the minimum `threshold` is `1`, the timelock duration is correctly added to the current timestamp instead of staying at `0`.

## Testing
A test suite is included in `test/EvictionVaultTest.t.sol` using Foundry. It contains tests that demonstrate the security fixes and basic functionality.

To run the tests:
```bash
forge test
