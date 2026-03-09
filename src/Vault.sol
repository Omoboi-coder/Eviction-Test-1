// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MultiSig.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract Vault is MultiSig {
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        // Fixed the (.transfer): to  (.call)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    // Fixed the (setMerkleRoot Callable by Anyone) to only MultiSig contract
    function setMerkleRoot(bytes32 root) external onlyMultisig {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(
        bytes32[] calldata proof,
        uint256 amount
    ) external whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        require(computed == merkleRoot, "Invalid proof");
        require(!claimed[msg.sender], "Already claimed");

        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        // Fixed the (.transfer): to  (.call)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
    }

    // Fixed the (emergencyWithdrawAll Public Drain)  access to only MultiSig
    function emergencyWithdrawAll(address payable to) external onlyMultisig {
        uint256 amount = address(this).balance;
        totalVaultValue = 0;

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Fixed the (Pause Single Owner Control) so pausing the system requires MultiSig agreement
    function pause() external onlyMultisig {
        paused = true;
    }

    // Fixed the (Unpause Single Owner Control) so unpausing the system requires MultiSig agreement
    function unpause() external onlyMultisig {
        paused = false;
    }
}
