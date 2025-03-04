// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.28;

// import "forge-std/Test.sol";
// import "../src/FreelancerContract.sol";
// import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// contract MockERC20 is ERC20 {
//     constructor() ERC20("MockToken", "MTK") {
//         _mint(msg.sender, 1_000_000 * 10 ** decimals());
//     }
// }

// contract FreelancerContractTest is Test {
//     FreelancerContract freelancerContract;
//     MockERC20 token;
//     address owner = address(1);
//     address freelancer = address(2);
//     address business = address(3);
//     address oracle = address(4);
//     string constant businessId = "biz123";
//     string constant freelancerId = "free123";
//     string constant projectId = "proj123";
//     string constant milestoneId = "mile123";
//     string constant escrowId = "escrow123";

//     function setUp() public {
//         vm.startPrank(owner);
//         freelancerContract = new FreelancerContract();
//         token = new MockERC20();
//         freelancerContract.addBusinessToDehix(businessId, business);
//         freelancerContract.addFreelancerToDehix(freelancerId, freelancer);
//         freelancerContract.createProjectToDehix(businessId, projectId);
//         freelancerContract.addMilestoneToDehix(projectId, 1, milestoneId);
//         freelancerContract.assignOracleToDehix("oracle123", oracle);
//         vm.stopPrank();
//     }

//     function testAddFreelancer() public {
//         vm.startPrank(owner);
//         freelancerContract.addFreelancerToDehix("free456", address(5));
//         (, address retrievedAddress) = freelancerContract.freelancers("free456");
//         assertEq(retrievedAddress, address(5));
//         vm.stopPrank();
//     }

//     function testDepositFundsToEscrow() public {
//         vm.startPrank(business);
//         token.approve(address(freelancerContract), 1000);
//         address[] memory addresses = new address[](1);
//         addresses[0] = oracle;
//         freelancerContract.createEscrow(escrowId, addresses, freelancer, business, projectId, address(token));
//         freelancerContract.depositFundsToEscrow(1000, escrowId);
//         (, , , , uint256 depositedAmount, ) = freelancerContract.escrow(escrowId);
//         assertEq(depositedAmount, 1000);
//         vm.stopPrank();
//     }

//     function testReleaseFunds() public {
//         vm.startPrank(business);
//         token.approve(address(freelancerContract), 1000);
//         address[] memory addresses = new address[](1);
//         addresses[0] = oracle;
//         freelancerContract.createEscrow(escrowId, addresses, freelancer, business, projectId, address(token));
//         freelancerContract.depositFundsToEscrow(1000, escrowId);
//         vm.stopPrank();

//         vm.startPrank(oracle);
//         freelancerContract.vote(true);
//         vm.stopPrank();

//         vm.startPrank(business);
//         freelancerContract.releaseEscrowFunds(escrowId);
//         assertEq(token.balanceOf(freelancer), 1000);
//         vm.stopPrank();
//     }

//     function testRefundFunds() public {
//         vm.startPrank(business);
//         token.approve(address(freelancerContract), 1000);
//         address[] memory addresses = new address[](1);
//         addresses[0] = oracle;
//         freelancerContract.createEscrow(escrowId, addresses, freelancer, business, projectId, address(token));
//         freelancerContract.depositFundsToEscrow(1000, escrowId);
//         vm.stopPrank();

//         vm.startPrank(oracle);
//         freelancerContract.vote(false);
//         vm.stopPrank();

//         vm.startPrank(freelancer);
//         freelancerContract.refundFundsOfEscrow(escrowId);
//         assertEq(token.balanceOf(business), 1000);
//         vm.stopPrank();
//     }
// }

