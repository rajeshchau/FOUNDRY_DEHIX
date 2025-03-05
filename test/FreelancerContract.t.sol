// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {FreelancerContract} from "../src/FreelancerContract.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "../src/Token.sol";

contract FreelancerContractTest is Test {
    FreelancerContract public freelancerContract;
    address public owner = address(this);
    address public businessAddress = address(0x123);
    address public freelancerAddress = address(0x456);
    MyToken public token;

    function setUp() public {
        token = new MyToken();
        token.mint(businessAddress, 10000); // Mint 10,000 tokens to businessAddress
        freelancerContract = new FreelancerContract();
        // Move project creation to tests requiring it to avoid redundant setup
    }

    function testAddFreelancer() public {
        vm.startPrank(owner);
        freelancerContract.addFreelancerToDehix("freelancer1", freelancerAddress);
        vm.stopPrank();

        (string memory id, address addr) = freelancerContract.freelancers("freelancer1");
        assertEq(id, "freelancer1", "Freelancer ID mismatch");
        assertEq(addr, freelancerAddress, "Freelancer address mismatch");
    }

    function testCreateProject() public {
        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        string memory projectId = freelancerContract.createProjectToDehix("business1", "project1");
        vm.stopPrank();

        assertEq(projectId, "project1", "Project ID mismatch");
    }

    function testAddMilestoneUnique() public {
        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.addMilestone("project1", 1, "milestone1");
        vm.stopPrank();

        (string memory milestoneId,, uint256 milestoneNumber,) =
            freelancerContract.getMilestone("project1", "milestone1");
        assertEq(milestoneId, "milestone1", "Milestone ID mismatch");
        assertEq(milestoneNumber, 1, "Milestone number mismatch");
    }

    function testAddBusiness() public {
        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        vm.stopPrank();
    }

    function testAddBusinessDuplicate() public {
        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        
        // Attempt to add the same business ID again
        vm.expectRevert("Business ID already exists");
        freelancerContract.addBusiness("business1", businessAddress);
        vm.stopPrank();
    }

    function testAddMilestone() public {
        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.addMilestone("project1", 1, "milestone1");
        vm.stopPrank();

        (string memory milestoneId,, uint256 milestoneNumber,) =
            freelancerContract.getMilestone("project1", "milestone1");
        assertEq(milestoneId, "milestone1", "Milestone ID mismatch");
        assertEq(milestoneNumber, 1, "Milestone number mismatch");
    }

    function testAddFreelancerPayment() public {
        string memory milestoneId = "milestone1";
        string memory projectId = "project1";
        string memory freelancerId = "freelancer1";
        uint256 amount = 1000;
        FreelancerContract.State state = FreelancerContract.State.Pending;

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", projectId);
        freelancerContract.addMilestone(projectId, 1, milestoneId);
        freelancerContract.addFreelancerPayment(milestoneId, freelancerId, projectId, amount, state);
        vm.stopPrank();

        (string memory fId, string memory pId, uint256 totalAmt, FreelancerContract.State s) =
            freelancerContract.getFreelancerPayment(projectId, milestoneId, 0);

        assertEq(fId, freelancerId, "Freelancer ID mismatch");
        assertEq(pId, projectId, "Project ID mismatch");
        assertEq(totalAmt, amount, "Total amount mismatch");
        assertEq(uint256(s), uint256(state), "State mismatch");
    }

    function testCreateEscrow() public {
        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow("escrow1", votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        (string memory escrowId, address[] memory oracles, address freelancer, address business, string memory projectId, uint256 depositedAmount) =
            freelancerContract.escrow("escrow1");
        assertEq(escrowId, "escrow1", "Escrow ID mismatch");
        assertEq(oracles.length, 3, "Oracle count mismatch");
        assertEq(freelancer, freelancerAddress, "Freelancer address mismatch");
        assertEq(business, businessAddress, "Business address mismatch");
        assertEq(projectId, "project1", "Project ID mismatch");
        assertEq(depositedAmount, 0, "Deposited amount should be 0 initially");
    }

    function testDepositFundsToEscrow() public {
        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow("escrow1", votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        uint256 amount = 1000;

        vm.startPrank(businessAddress);
        token.approve(address(freelancerContract), amount);
        assertEq(token.allowance(businessAddress, address(freelancerContract)), amount, "Allowance not set correctly");
        freelancerContract.depositFundsToEscrow(amount, "escrow1");
        vm.stopPrank();

        (, , , , , uint256 depositedAmount) = freelancerContract.escrow("escrow1");
        assertEq(depositedAmount, amount, "Deposited amount mismatch");
    }

   function testReleaseEscrowFunds() public {
    address[] memory votingOracles = new address[](3);
    votingOracles[0] = address(0x789);
    votingOracles[1] = address(0xabc);
    votingOracles[2] = address(0xdef);

    vm.startPrank(owner);
    freelancerContract.addBusiness("business1", businessAddress);
    freelancerContract.createProjectToDehix("business1", "project1");
    freelancerContract.createEscrow("escrow1", votingOracles, freelancerAddress, businessAddress, "project1", address(token));
    vm.stopPrank();

    uint256 amount = 1000;

    // Deposit funds
    vm.startPrank(businessAddress);
    token.approve(address(freelancerContract), amount);
    freelancerContract.depositFundsToEscrow(amount, "escrow1");
    vm.stopPrank();

    // Simulate voting
    vm.startPrank(votingOracles[0]);
    freelancerContract.vote(true);
    vm.stopPrank();

    vm.startPrank(votingOracles[1]);
    freelancerContract.vote(true);
    vm.stopPrank();

    vm.startPrank(votingOracles[2]);
    freelancerContract.vote(true);
    vm.stopPrank();

    // Record initial balances
    uint256 freelancerInitialBalance = token.balanceOf(freelancerAddress);
    uint256 contractInitialBalance = token.balanceOf(address(freelancerContract));

    // Release funds (called by businessAddress, the buyer)
    vm.startPrank(businessAddress);
    freelancerContract.releaseEscrowFunds("escrow1");
    vm.stopPrank();

    // Assertions
    uint256 freelancerNewBalance = token.balanceOf(freelancerAddress);
    uint256 contractNewBalance = token.balanceOf(address(freelancerContract));
    (, , , , , uint256 depositedAmount) = freelancerContract.escrow("escrow1");

    assertEq(
        freelancerNewBalance,
        freelancerInitialBalance + amount,
        "Freelancer should receive the deposited amount"
    );
    assertEq(
        contractNewBalance,
        contractInitialBalance - amount,
        "Contract should have transferred the funds"
    );
    assertEq(depositedAmount, 0, "Escrow deposited amount should be 0 after release");
}

    function testRefundFundsOfEscrow() public {
        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow("escrow1", votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        uint256 amount = 1000;

        // Deposit funds
        vm.startPrank(businessAddress);
        token.approve(address(freelancerContract), amount);
        freelancerContract.depositFundsToEscrow(amount, "escrow1");
        vm.stopPrank();

        // Simulate voting for refund
        vm.startPrank(votingOracles[0]);
        freelancerContract.vote(false);
        vm.stopPrank();

        vm.startPrank(votingOracles[1]);
        freelancerContract.vote(false);
        vm.stopPrank();

        vm.startPrank(votingOracles[2]);
        freelancerContract.vote(false);
        vm.stopPrank();

        // Record initial balances
        uint256 businessInitialBalance = token.balanceOf(businessAddress);
        uint256 contractInitialBalance = token.balanceOf(address(freelancerContract));

        // Refund funds
        vm.startPrank(freelancerAddress);
        freelancerContract.refundFundsOfEscrow("escrow1");
        vm.stopPrank();

        // Assertions
        uint256 businessNewBalance = token.balanceOf(businessAddress);
        uint256 contractNewBalance = token.balanceOf(address(freelancerContract));
        (, , , , , uint256 depositedAmount) = freelancerContract.escrow("escrow1");

        assertEq(
            businessNewBalance,
            businessInitialBalance + amount,
            "Business should receive the refunded amount"
        );
        assertEq(
            contractNewBalance,
            contractInitialBalance - amount,
            "Contract should have transferred the funds"
        );
        assertEq(depositedAmount, 0, "Escrow deposited amount should be 0 after refund");
    }
}
