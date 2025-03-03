// SPDX-License-Identifier: MIT

// @audit: different version of solidity is used in this file
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FreelancerContract {
    using SafeERC20 for IERC20;
    //q why it is starting with paid state ?

    enum State {
        Paid,
        Unpaid,
        Pending
    }

    struct FreelancerPayment {
        string freelancerId;
        string projectId;
        uint256 totalAmount;
        State state;
    }

    struct Milestone {
        string milestoneId;
        string projectId;
        uint256 milestoneNumber;
        uint256 milestoneCompleted;
        mapping(uint256 => FreelancerPayment) freelancerPayments;
    }

    struct Project {
        string projectId;
        bool isActive;
        uint256 totalApplications;
        mapping(string => uint256) appliedFreelancers;
        mapping(string => Milestone) milestones;
    }

    struct Freelancer {
        string freelancerId;
        address freelancerAddress;
        mapping(string => Project) projects;
    }

    struct Business {
        string businessId;
        address businessAddress;
        mapping(string => Project) projects;
    }

    struct Hiring {
        string hiringId;
        mapping(string => Freelancer) freelancers;
        bool feesStatus;
    }

    struct Oracle {
        string oracleId;
        address oracleAddress;
    }

    struct Escrow {
        string escrowid;
        address[] votingoracles;
        address freelanceraddress;
        address bussnessadress;
        string projectid;
        uint256 depositedamount;
        IERC20 tokenaddress;
    }
    //q why owner is immutable ?

    address private immutable owner;

    mapping(string => Freelancer) public freelancers;
    mapping(string => Project) public projects;
    mapping(string => Business) public businesses;
    mapping(string => Hiring) public hirings;
    mapping(string => Oracle) public oracles;
    mapping(string => Escrow) public escrow;

    mapping(address => bool) public isOracles;
    mapping(address => mapping(bool => bool)) public oracleVotes;

    string private nextFreelancerId; //q is this never used?
    string private nextProjectId; //q is this never used?
    string private nextBusinessId; //q is this never used?
    string private nextMilestoneId; //q is this never used?
    string private nextHiringId; //q is this never used?
    address[] public Orecles; // q should oreacles be public ?

    event FreelancerAdded(string indexed freelancerId, address freelancerAddress);// q is it required to use indexed ?
    event ProjectCreated(string indexed projectId, bool isActive);// q is it required to use indexed ?
    event MilestoneAdded(string indexed projectId, string milestoneId);// q is it required to use indexed ?
    event PaymentAdded(string indexed milestoneId, uint256 paymentId);// q is it required to use indexed ?
    event FundsDeposited(address businessaddress, uint256 amount);
    event FundsReleased(address freelanceraddress, uint256 amount);
    event FundsRefunded(address freelanceraddress, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
    // q is this modifier used more than one ?

    modifier onlyBuyerOrOracle(string memory _escrowid) {
        require(msg.sender == escrow[_escrowid].bussnessadress || isOracles[msg.sender], "Not Authorized!");
        _;
    }

    modifier onlyWhenDeposited(string memory _escrowid) {
        require(escrow[_escrowid].depositedamount > 0, "No funds to release or refund!");
        _;
    }

    modifier onlySellerOrOrecle(string memory _escrowid) {
        require(msg.sender == escrow[_escrowid].freelanceraddress || isOracles[msg.sender], "Not Authorized!");
        _;
    }
<<<<<<< HEAD
    // q why there are no require statement in this function  and why it is not checking bussness id existance?
=======
    // @audit: access control exploit
>>>>>>> 14fca3274fab1bd3cc8104e4bfb911b63b54e593
    function addBusinessToDehix(string memory _bussinessid, address _bussinessaddress) public {
        businesses[_bussinessid].businessId = _bussinessid;
        businesses[_bussinessid].businessAddress = _bussinessaddress;
    }

    function addFreelancerToDehix(string memory _freelancerid, address _freelancerAddress) external onlyOwner {
        require(bytes(_freelancerid).length != 0, "Freelancer ID cannot be empty");
        require(
            keccak256(bytes(_freelancerid)) != keccak256(bytes(freelancers[_freelancerid].freelancerId)),
            "Freelancer ID already exists"
        );
        require(_freelancerAddress != address(0), "Freelancer address cannot be 0");

        freelancers[_freelancerid].freelancerId = _freelancerid;
        freelancers[_freelancerid].freelancerAddress = _freelancerAddress;
        emit FreelancerAdded(_freelancerid, _freelancerAddress);
    }

    function createProjectToDehix(string memory _businessId, string memory _projectid)
        external
        onlyOwner
        returns (string memory)
    {
        require(bytes(_projectid).length != 0, "Project ID cannot be empty");
        projects[_projectid].projectId = _projectid;
        projects[_projectid].isActive = true;

        //q is there any requirement for project to be storage?

        Project storage project = projects[_projectid];
        businesses[_businessId].projects[_projectid].projectId = project.projectId;
        businesses[_businessId].projects[_projectid].isActive = project.isActive;
        businesses[_businessId].projects[_projectid].totalApplications = project.totalApplications;
        emit ProjectCreated(_projectid, true);
        return _projectid;
    }

    function addMilestoneToDehix(string memory _projectId, uint256 _milestoneNumber, string memory _milestoneid)
        external
        onlyOwner
    {
        //q is there any requirement for project to be storage?
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is not active");

        project.milestones[_milestoneid].milestoneId = _milestoneid;
        project.milestones[_milestoneid].projectId = _projectId;
        project.milestones[_milestoneid].milestoneNumber = _milestoneNumber;
        project.milestones[_milestoneid].milestoneCompleted = 0;

        emit MilestoneAdded(_projectId, _milestoneid);
    }

    function addFreelancerPaymentToDehix(
        string memory _milestoneId,
        string memory _freelancerId,
        string memory _projectId,
        uint256 _amount,
        State _state
    ) external onlyOwner {
        Milestone storage milestone = projects[_projectId].milestones[_milestoneId];
        // q are you sure paymentid should be milestoneCompleted++ ?
        uint256 paymentId = milestone.milestoneCompleted++;
        milestone.freelancerPayments[paymentId] =
            FreelancerPayment({freelancerId: _freelancerId, projectId: _projectId, totalAmount: _amount, state: _state});

        emit PaymentAdded(_milestoneId, paymentId);
    }

    function applyToProjectToDehix(string memory _projectId, string memory _freelancerId) external {
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is not active");
        // q there can be some issue with this line of code
        project.appliedFreelancers[_freelancerId] = 1; // Mark freelancer as applied
        project.totalApplications++;
    }

    // q why this should be only owner and not bussness?
    function deactivateProjectToDehix(string memory _projectId) external onlyOwner {
        projects[_projectId].isActive = false;
    }

    // q why this should be only owner and not bussness?

    function assignOracleToDehix(string memory _oracleId, address _oracleAddress) external onlyOwner {
        oracles[_oracleId].oracleId = _oracleId;
        oracles[_oracleId].oracleAddress = _oracleAddress;
    }

    // Additional getters for retrieving nested mapping data
    function getMilestone(string memory _projectId, string memory _milestoneId)
        external
        view
        returns (string memory, string memory, uint256, uint256)
    {
        Milestone storage milestone = projects[_projectId].milestones[_milestoneId];
        return (milestone.milestoneId, milestone.projectId, milestone.milestoneNumber, milestone.milestoneCompleted);
    }

    // q are you sure this is correct?
    function getFreelancerPayment(string memory _projectId, string memory _milestoneId, uint256 _paymentId)
        external
        view
        returns (string memory, string memory, uint256, State)
    {
        FreelancerPayment storage payment = projects[_projectId].milestones[_milestoneId].freelancerPayments[_paymentId];
        return (payment.freelancerId, payment.projectId, payment.totalAmount, payment.state);
    }
<<<<<<< HEAD

    //q 
    function createEscrow(
        string memory _escrowid,
        address[] memory _votingoracle,
        address _freelancer,
        address _bussness,
        string memory _projectid,
        address _tokenaddress
    ) public {
        require(
            _votingoracle.length == 1 || _votingoracle.length == 3 || _votingoracle.length == 5,
            "Number of arbiters must be 1, 3, or 5"
        );
        escrow[_escrowid].escrowid = _escrowid;
        escrow[_escrowid].votingoracles = _votingoracle;
        escrow[_escrowid].freelanceraddress = _freelancer;
        escrow[_escrowid].bussnessadress = _bussness;
        escrow[_escrowid].projectid = _projectid;
=======
    // q: who can create escrow
    // @audit: access control exploit
    function createEscrow(string memory _escrowid,address[] memory _votingoracle,address _freelancer,address _bussness,string memory _projectid,address _tokenaddress)public{
        require(_votingoracle.length == 1 || _votingoracle.length == 3 || _votingoracle.length == 5,"Number of arbiters must be 1, 3, or 5");
        escrow[_escrowid].escrowid=_escrowid;
        escrow[_escrowid].votingoracles=_votingoracle;
        escrow[_escrowid].freelanceraddress=_freelancer;
        escrow[_escrowid].bussnessadress=_bussness;
        escrow[_escrowid].projectid=_projectid;
>>>>>>> 14fca3274fab1bd3cc8104e4bfb911b63b54e593
        escrow[_escrowid].depositedamount = 0;
        escrow[_escrowid].tokenaddress = IERC20(_tokenaddress);
        // q can we avoid this loop here ? 
        for (uint256 i = 0; i < _votingoracle.length; i++) {
            require(_votingoracle[i] != address(0), "Arbiter address cannot be zero");
            Orecles.push(_votingoracle[i]);
            isOracles[_votingoracle[i]] = true;
        }
    }

<<<<<<< HEAD
    //q why the user can't deposite multiple times?
    // function depositFundsToEscrow(uint256 _amount, string memory _escrowid) external {
    //     require(msg.sender == escrow[_escrowid].bussnessadress, "Only buyer can deposit funds!");
    //     require(_amount > 0, "Deposit must be greater than zero!");
    //     require(escrow[_escrowid].depositedamount == 0, "Funds already deposited!");
=======
    // @audit: DOS attack -> no fallback for faliure
    function depositFundsToEscrow(uint256 _amount,string memory _escrowid) external {
        require(msg.sender == escrow[_escrowid].bussnessadress, "Only buyer can deposit funds!");
        require(_amount > 0, "Deposit must be greater than zero!");
        require(escrow[_escrowid].depositedamount == 0, "Funds already deposited!");
>>>>>>> 14fca3274fab1bd3cc8104e4bfb911b63b54e593

    //     // Transfer tokens from buyer to this contract securely
    //     escrow[_escrowid].tokenaddress.safeTransferFrom(msg.sender, address(this), _amount);

    //     escrow[_escrowid].depositedamount = _amount;
    //     emit FundsDeposited(msg.sender, _amount);
    // }

<<<<<<< HEAD
    function depositFundsToEscrow(uint256 _amount, string memory _escrowid) external {
    require(msg.sender == escrow[_escrowid].bussnessadress, "Only buyer can deposit funds!");
    require(_amount > 0, "Deposit must be greater than zero!");

    // Securely transfer tokens
    escrow[_escrowid].tokenaddress.safeTransferFrom(msg.sender, address(this), _amount);

    // Allow accumulation instead of restricting to a single deposit
    escrow[_escrowid].depositedamount += _amount;  

    emit FundsDeposited(msg.sender, _amount);
}

    function releaseEscrowFunds(string memory _escrowid)
        external
        onlyBuyerOrOracle(_escrowid)
        onlyWhenDeposited(_escrowid)
    {
=======
    // @audit: Reentrancy issue
    function releaseEscrowFunds(string memory _escrowid) external onlyBuyerOrOracle(_escrowid) onlyWhenDeposited(_escrowid) {
>>>>>>> 14fca3274fab1bd3cc8104e4bfb911b63b54e593
        require(_majorityVote(true), "Majority vote required to release funds!");

        // Transfer tokens to seller securely
        escrow[_escrowid].tokenaddress.safeTransfer(
            escrow[_escrowid].freelanceraddress, escrow[_escrowid].depositedamount
        );

        emit FundsReleased(escrow[_escrowid].freelanceraddress, escrow[_escrowid].depositedamount);
        escrow[_escrowid].depositedamount = 0;
    }

    // @audit: DOS attack
    // @audit: precision loss
    function _majorityVote(bool release) private view returns (bool) {
        uint256 votes = 0;
        // q can wer use a memory  varriable to store the length of Orecles?
        // q is there any requrement of forloop.
        for (uint256 i = 0; i < Orecles.length; i++) {
            if (_orecleVoted(Orecles[i], release)) {
                votes++;
            }
        }
        // Majority is half the arbiters plus one
        return votes > Orecles.length / 2;
    }

    function vote(bool release) external {
        require(isOracles[msg.sender], "Only arbiters can vote!");
        oracleVotes[msg.sender][release] = true;
    }

<<<<<<< HEAD
    function refundFundsOfEscrow(string memory _escrowid)
        external
        onlySellerOrOrecle(_escrowid)
        onlyWhenDeposited(_escrowid)
    {
=======
    // @audit: reentrancy issue
    function refundFundsOfEscrow(string memory _escrowid) external onlySellerOrOrecle(_escrowid) onlyWhenDeposited(_escrowid) {
>>>>>>> 14fca3274fab1bd3cc8104e4bfb911b63b54e593
        require(_majorityVote(false), "Majority vote required to refund funds!");

        // Transfer tokens back to buyer securely
        escrow[_escrowid].tokenaddress.safeTransfer(escrow[_escrowid].bussnessadress, escrow[_escrowid].depositedamount);

        emit FundsRefunded(escrow[_escrowid].bussnessadress, escrow[_escrowid].depositedamount);
        escrow[_escrowid].depositedamount = 0;
    }

    function _orecleVoted(address _orecle, bool _release) private view returns (bool) {
        return oracleVotes[_orecle][_release];
    }
}
