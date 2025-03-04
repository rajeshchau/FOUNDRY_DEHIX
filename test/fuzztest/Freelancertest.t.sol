// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.28;

// import {Test} from "forge-std/Test.sol";
// import {FreelancerContract} from "../../src/FreelancerContract.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract FreelancerContractTest is Test {
//     FreelancerContract public freelancerContract;
//     address public owner = address(this);
//     IERC20 public token;

//     function setUp() public {
//         freelancerContract = new FreelancerContract();
//     }

//     function testAddFreelancerFuzz(string memory _freelancerId, address _freelancerAddress) public {
//         vm.assume(bytes(_freelancerId).length > 0); // Ensure freelancerId is not empty
//         vm.assume(_freelancerAddress != address(0)); // Ensure a valid address

//         freelancerContract.addFreelancerToDehix(_freelancerId, _freelancerAddress);
        
//         (string memory id, address addr) = freelancerContract.freelancers(_freelancerId);
//         assertEq(id, _freelancerId);
//         assertEq(addr, _freelancerAddress);
//     }
//     function testAddBussnessfuzz(string memory _bussinessid, address _bussinessaddress) public {
//         freelancerContract.addBusinessToDehix(_bussinessid, _bussinessaddress);
//         (string memory id, address addr) = freelancerContract.businesses(_bussinessid);
//         assertEq(id, _bussinessid);
//         assertEq(addr, _bussinessaddress);
//     } 
    

// }
