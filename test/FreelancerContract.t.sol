// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {FreelancerContract} from "../src/FreelancerContract.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract FreelancerContractTest is Test {
    FreelancerContract public freelancerContract;
    address public owner = address(this);
    address public businessAddress = address(0x123);
    address public freelancerAddress = address(0x456);
    IERC20 public token;

    function setUp() public {
        freelancerContract = new FreelancerContract();
        freelancerContract.createProjectToDehix("project123", "project123");
    }

    function testAddFreelancer() public {
        freelancerContract.addFreelancerToDehix("freelancer1", freelancerAddress);
        (string memory id, address addr) = freelancerContract.freelancers("freelancer1");
        assertEq(id, "freelancer1");
        assertEq(addr, freelancerAddress);
    }


    function testCreateProject() public {
        freelancerContract.addBusinessToDehix("business1", businessAddress);
        string memory projectId = freelancerContract.createProjectToDehix("business1", "project1");
        assertEq(projectId, "project1");
    }

    function testAddMilestone() public {
        freelancerContract.addBusinessToDehix("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.addMilestoneToDehix("project1", 1, "milestone1");
        (string memory milestoneId,, uint256 milestoneNumber,) =
            freelancerContract.getMilestone("project1", "milestone1");
        assertEq(milestoneId, "milestone1");
        assertEq(milestoneNumber, 1);
    }

    function testAddBussnessToDehix() public {
        freelancerContract.addBusinessToDehix("business1", businessAddress);
        (string memory id, address addr) = freelancerContract.businesses("business1");
        assertEq(id, "business1");
        assertEq(addr, businessAddress);
    }

    function testAddMilestoneToDehix() public {
        freelancerContract.addBusinessToDehix("business1", businessAddress);
        freelancerContract.createProjectToDehix("business1", "project1");
        freelancerContract.addMilestoneToDehix("project1", 1, "milestone1");
        (string memory milestoneId,, uint256 milestoneNumber,) =
            freelancerContract.getMilestone("project1", "milestone1");
        assertEq(milestoneId, "milestone1");
        assertEq(milestoneNumber, 1);
    }

    function testAddFreelancerPayment() public {
        string memory milestoneId = "milestone1";
        string memory projectId = "project1";
        string memory freelancerId = "freelancer1";
        uint256 amount = 1000;
        FreelancerContract.State state = FreelancerContract.State.Pending;

        vm.startPrank(owner);

        // Set up initial project and milestone
        freelancerContract.createProjectToDehix("business1", projectId);
        freelancerContract.addMilestoneToDehix(projectId, 1, milestoneId);

        // Add freelancer payment
        freelancerContract.addFreelancerPaymentToDehix(milestoneId, freelancerId, projectId, amount, state);

        (string memory fId, string memory pId, uint256 totalAmt, FreelancerContract.State s) =
            freelancerContract.getFreelancerPayment(projectId, milestoneId, 0);

        assertEq(fId, freelancerId, "Freelancer ID mismatch");
        assertEq(pId, projectId, "Project ID mismatch");
        assertEq(totalAmt, amount, "Total amount mismatch");
        assertEq(uint256(s), uint256(state), "State mismatch");

        vm.stopPrank();
    }


    
    // function testGetFreelancerPayment () public {
    //     freelancerContract.addBusinessToDehix("business1", businessAddress);
    //     freelancerContract.createProjectToDehix("business1", "project1");
    //     freelancerContract.addMilestoneToDehix("project1", 1, "milestone1");
    //     freelancerContract.addFreelancerPaymentToDehix("project1", "milestone1", freelancerAddress, 100);
    //     uint256 amount = freelancerContract.getFreelancerPayment("project1", "milestone1", freelancerAddress);
    //     assertEq(amount, 100);
    // }
}
