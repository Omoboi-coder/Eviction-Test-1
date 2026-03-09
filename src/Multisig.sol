// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EvictionVaultStorage.sol";

abstract contract MultiSig is EvictionVaultStorage {
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    function submitTransaction(address to, uint256 value, bytes calldata data)
     external onlyOwner whenNotPaused {
        uint256 id = txCount++;
        
        // Fixed TimeLock bypass 
        uint256 executionTime = 0;
        if (threshold == 1) {
            executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: executionTime
        });
        
        confirmed[id][msg.sender] = true;
        emit Submission(id);
        emit Confirmation(id, msg.sender);
    }

    function confirmTransaction(uint256 txId) external onlyOwner whenNotPaused {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "Tx already executed");
        require(!confirmed[txId][msg.sender], "Tx already confirmed");
        
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "Wait for threshold");
        require(!txn.executed, "Already executed");
        require(block.timestamp >= txn.executionTime, "Timelock not met");
        
        txn.executed = true;
        (bool s,) = txn.to.call{value: txn.value}(txn.data);
        require(s, "Transaction execution failed");
        
        emit Execution(txId);
    }
}
