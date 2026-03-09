// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault public vault;
    address public owner1 = address(0x11);
    address public owner2 = address(0x22);
    address public user = address(0x33);

    function setUp() public {
        vm.deal(owner1, 100 ether);
        vm.deal(owner2, 100 ether);
        vm.deal(user, 100 ether);

        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        vault = new EvictionVault{value: 10 ether}(owners, 2);
    }

    // 1. Test receive tracks msg.sender and not tx.origin
    function test_DepositAndReceive() public {
        vm.prank(user);
        (bool s,) = address(vault).call{value: 1 ether}("");
        require(s, "Deposit failed");
        
        uint256 balance = vault.balances(user);
        assertEq(balance, 1 ether);
    }

    // 2. Test withdraw securely uses .call instead of .transfer
    function test_WithdrawSecurely() public {
        vm.startPrank(user);
        vault.deposit{value: 2 ether}();
        
        uint256 preBalance = user.balance;
        vault.withdraw(1 ether);
        uint256 postBalance = user.balance;
        
        assertEq(postBalance - preBalance, 1 ether);
        assertEq(vault.balances(user), 1 ether);
        vm.stopPrank();
    }

    // 3. Test Timelock Execution logic (bug fixed)
    function test_TimelockExecution() public {
        address[] memory singleOwner = new address[](1);
        singleOwner[0] = owner1;
        EvictionVault singleVault = new EvictionVault(singleOwner, 1);

        vm.prank(owner1);
        singleVault.submitTransaction(user, 0, "");

        // If threshold == 1, the execution time should be set properly 
        (, , , , , , uint256 executionTime) = singleVault.transactions(0);
        assertTrue(executionTime > 0, "Timelock bypassed if execution time is 0");

        vm.warp(block.timestamp + 1 hours);
        
        vm.prank(owner1);
        singleVault.executeTransaction(0);
        
        (,,,bool executed,,,) = singleVault.transactions(0);
        assertTrue(executed, "Transaction not executed");
    }

    // 4. Test setMerkleRoot restricted securely to multisig
    function test_SecureSetMerkleRoot() public {
        bytes32 newRoot = keccak256("root");

        vm.prank(address(vault));
        vault.setMerkleRoot(newRoot);
        
        assertEq(vault.merkleRoot(), newRoot);

        // Prove anyone else fails
        vm.prank(user);
        vm.expectRevert("EvictionVault: only multisig allowed");
        vault.setMerkleRoot(keccak256("failRoot"));
    }

    // 5. Test emergencyWithdrawAll restricted securely to multisig
    function test_SecureEmergencyWithdrawAll() public {
        uint256 vaultBal = address(vault).balance;
        address payable recovery = payable(address(0x99));
        
        // Prank as the vault itself
        vm.prank(address(vault));
        vault.emergencyWithdrawAll(recovery);
        
        assertEq(recovery.balance, vaultBal);
        assertEq(address(vault).balance, 0);

        // Prove anyone else fails
        vm.prank(user);
        vm.expectRevert("EvictionVault: only multisig allowed");
        vault.emergencyWithdrawAll(recovery);
    }

    // 6. Test pause/unpause properly restricted to multisig
    function test_SecurePauseUnpause() public {
        // Prank as the vault itself
        vm.prank(address(vault));
        vault.pause();
        assertTrue(vault.paused(), "Vault should be paused");

        // Prove anyone else fails
        vm.prank(owner1);
        vm.expectRevert("EvictionVault: only multisig allowed");
        vault.pause();
    }
}
