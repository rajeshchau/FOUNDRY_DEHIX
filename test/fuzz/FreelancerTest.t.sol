// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {FreelancerContract} from "../../src/FreelancerContract.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MyToken} from "../../src/Token.sol";

contract FreelancerContractFuzzTest is Test {
    FreelancerContract public freelancerContract;
    address public owner = address(this);
    address public businessAddress = address(0x123);
    address public freelancerAddress = address(0x456);
    MyToken public token;

    function setUp() public {
        token = new MyToken();
        token.mint(businessAddress, 10000); // Mint initial tokens to businessAddress
        freelancerContract = new FreelancerContract();
    }

    function testFuzzAddFreelancer(string memory freelancerId, address freelancerAddr) public {
        vm.assume(bytes(freelancerId).length > 0); // Non-empty ID
        vm.assume(freelancerAddr != address(0));   // Non-zero address

        vm.startPrank(owner);
        freelancerContract.addFreelancerToDehix(freelancerId, freelancerAddr);
        vm.stopPrank();

        (string memory id, address addr) = freelancerContract.freelancers(freelancerId);
        assertEq(id, freelancerId, "Freelancer ID mismatch");
        assertEq(addr, freelancerAddr, "Freelancer address mismatch");
    }

    function testFuzzCreateProject(string memory businessId, string memory projectId) public {
        vm.assume(bytes(businessId).length > 0); // Non-empty business ID
        vm.assume(bytes(projectId).length > 0);  // Non-empty project ID

        vm.startPrank(owner);
        freelancerContract.addBusiness(businessId, businessAddress);
        string memory returnedProjectId = freelancerContract.createProjectToDehix(businessId, projectId);
        vm.stopPrank();

        assertEq(returnedProjectId, projectId, "Project ID mismatch");
    }

    function testFuzzAddMilestoneUnique(string memory projectId, uint256 milestoneNumber, string memory milestoneId) public {
        vm.assume(bytes(projectId).length > 0);   // Non-empty project ID
        vm.assume(bytes(milestoneId).length > 0); // Non-empty milestone ID
        vm.assume(milestoneNumber > 0);           // Valid milestone number

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", projectId);
        freelancerContract.addMilestone(projectId, milestoneNumber, milestoneId);
        vm.stopPrank();

        (string memory retrievedMilestoneId,, uint256 retrievedMilestoneNumber,) =
            freelancerContract.getMilestone(projectId, milestoneId);
        assertEq(retrievedMilestoneId, milestoneId, "Milestone ID mismatch");
        assertEq(retrievedMilestoneNumber, milestoneNumber, "Milestone number mismatch");
    }

    function testFuzzAddBusiness(string memory businessId, address businessAddr) public {
        vm.assume(bytes(businessId).length > 0); // Non-empty business ID
        vm.assume(businessAddr != address(0));   // Non-zero address

        vm.startPrank(owner);
        freelancerContract.addBusiness(businessId, businessAddr);
        vm.stopPrank();

        (string memory id, address addr) = freelancerContract.businesses(businessId);
        assertEq(id, businessId, "Business ID mismatch");
        assertEq(addr, businessAddr, "Business address mismatch");
    }

    function testFuzzAddMilestone(string memory projectId, uint256 milestoneNumber, string memory milestoneId) public {
        vm.assume(bytes(projectId).length > 0);   // Non-empty project ID
        vm.assume(bytes(milestoneId).length > 0); // Non-empty milestone ID
        vm.assume(milestoneNumber > 0);           // Valid milestone number

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", projectId);
        freelancerContract.addMilestone(projectId, milestoneNumber, milestoneId);
        vm.stopPrank();

        (string memory retrievedMilestoneId,, uint256 retrievedMilestoneNumber,) =
            freelancerContract.getMilestone(projectId, milestoneId);
        assertEq(retrievedMilestoneId, milestoneId, "Milestone ID mismatch");
        assertEq(retrievedMilestoneNumber, milestoneNumber, "Milestone number mismatch");
    }

   function testFuzzAddFreelancerPayment(
    string memory milestoneId,
    string memory freelancerId,
    string memory projectId,
    uint256 amount,
    uint8 state
) public {
    vm.assume(bytes(milestoneId).length > 0);  // Non-empty milestone ID
    vm.assume(bytes(freelancerId).length > 0); // Non-empty freelancer ID
    vm.assume(bytes(projectId).length > 0);    // Non-empty project ID
    vm.assume(amount > 0 && amount <= 10000);  // Valid amount within minted range
    vm.assume(state <= 2);                     // State is Paid(0), Unpaid(1), or Pending(2)

    vm.startPrank(owner);
    freelancerContract.addBusiness("business1", businessAddress);
    freelancerContract.createProjectToDehix("business1", projectId);
    freelancerContract.addMilestone(projectId, 1, milestoneId);
    freelancerContract.addFreelancerPayment(milestoneId, freelancerId, projectId, amount, FreelancerContract.State(state));
    vm.stopPrank();

    (string memory fId, string memory pId, uint256 totalAmt, FreelancerContract.State s) =
        freelancerContract.getFreelancerPayment(projectId, milestoneId, 0);

    assertEq(fId, freelancerId, "Freelancer ID mismatch");
    assertEq(pId, projectId, "Project ID mismatch");
    assertEq(totalAmt, amount, "Total amount mismatch");
    assertEq(uint256(s), uint256(state), "State mismatch");
}

    function testFuzzCreateEscrow(
        string memory escrowId,
        address[] memory votingOracles,
        address freelancer,
        address business,
        string memory projectId
    ) public {
        vm.assume(bytes(escrowId).length > 0);    // Non-empty escrow ID
        vm.assume(bytes(projectId).length > 0);   // Non-empty project ID
        vm.assume(freelancer != address(0));      // Non-zero freelancer address
        vm.assume(business != address(0));        // Non-zero business address
        vm.assume(votingOracles.length == 1 || votingOracles.length == 3 || votingOracles.length == 5); // Valid oracle count
        for (uint256 i = 0; i < votingOracles.length; i++) {
            vm.assume(votingOracles[i] != address(0)); // Non-zero oracle addresses
        }

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", business);
        freelancerContract.createProjectToDehix("business1", projectId);
        freelancerContract.createEscrow(escrowId, votingOracles, freelancer, business, projectId, address(token));
        vm.stopPrank();

        (string memory retrievedEscrowId, address[] memory oracles, address retrievedFreelancer, address retrievedBusiness, string memory retrievedProjectId, uint256 depositedAmount) =
            freelancerContract.escrow(escrowId);
        assertEq(retrievedEscrowId, escrowId, "Escrow ID mismatch");
        assertEq(oracles.length, votingOracles.length, "Oracle count mismatch");
        assertEq(retrievedFreelancer, freelancer, "Freelancer address mismatch");
        assertEq(retrievedBusiness, business, "Business address mismatch");
        assertEq(retrievedProjectId, projectId, "Project ID mismatch");
        assertEq(depositedAmount, 0, "Deposited amount should be 0 initially");
    }

    function testFuzzDepositFundsToEscrow(string memory escrowId, uint256 amount) public {
        vm.assume(bytes(escrowId).length > 0); // Non-empty escrow ID
        vm.assume(amount > 0 && amount <= 10000); // Valid amount within minted range

        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow(escrowId, votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        vm.startPrank(businessAddress);
        token.approve(address(freelancerContract), amount);
        freelancerContract.depositFundsToEscrow(amount, escrowId);
        vm.stopPrank();

        (, , , , , uint256 depositedAmount) = freelancerContract.escrow(escrowId);
        assertEq(depositedAmount, amount, "Deposited amount mismatch");
    }

    function testFuzzReleaseEscrowFunds(string memory escrowId, uint256 amount) public {
        vm.assume(bytes(escrowId).length > 0); // Non-empty escrow ID
        vm.assume(amount > 0 && amount <= 10000); // Valid amount within minted range

        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow(escrowId, votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        // Deposit funds
        vm.startPrank(businessAddress);
        token.approve(address(freelancerContract), amount);
        freelancerContract.depositFundsToEscrow(amount, escrowId);
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

        // Release funds
        vm.startPrank(businessAddress);
        freelancerContract.releaseEscrowFunds(escrowId);
        vm.stopPrank();

        // Assertions
        uint256 freelancerNewBalance = token.balanceOf(freelancerAddress);
        uint256 contractNewBalance = token.balanceOf(address(freelancerContract));
        (, , , , , uint256 depositedAmount) = freelancerContract.escrow(escrowId);

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

    function testFuzzRefundFundsOfEscrow(string memory escrowId, uint256 amount) public {
        vm.assume(bytes(escrowId).length > 0); // Non-empty escrow ID
        vm.assume(amount > 0 && amount <= 10000); // Valid amount within minted range

        address[] memory votingOracles = new address[](3);
        votingOracles[0] = address(0x789);
        votingOracles[1] = address(0xabc);
        votingOracles[2] = address(0xdef);

        vm.startPrank(owner);
        freelancerContract.addBusiness("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.createEscrow(escrowId, votingOracles, freelancerAddress, businessAddress, "project1", address(token));
        vm.stopPrank();

        // Deposit funds
        vm.startPrank(businessAddress);
        token.approve(address(freelancerContract), amount);
        freelancerContract.depositFundsToEscrow(amount, escrowId);
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
        freelancerContract.refundFundsOfEscrow(escrowId);
        vm.stopPrank();

        // Assertions
        uint256 businessNewBalance = token.balanceOf(businessAddress);
        uint256 contractNewBalance = token.balanceOf(address(freelancerContract));
        (, , , , , uint256 depositedAmount) = freelancerContract.escrow(escrowId);

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