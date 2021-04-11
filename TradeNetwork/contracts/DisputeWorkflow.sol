pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract Dispute {
    public party;
    public project;
    public eventsInstance;

    enum Status {None, Active, Accepted, Rejected}

    struct DisputeStruct {
        Status status;
        address project;
        uint256 taskId;
        address raisedBy;
        bytes reasonHash;
        bytes resultHash;
        mapping(address => bytes) otherBytes;
    }

    mapping(uint256 => DisputeStruct) public disputes;
    uint256 public disputeCount; //starts from 1

    constructor(address _padlock, address _eventsContract) {
        padlock = IPadlock(_padlock);
        eventsInstance = IEvents(_eventsContract);
    }

    modifier onlyPadlock() {
        require(address(padlock) == msg.sender, "Only padlock");
        _;
    }

    modifier onlyMember(address _project, uint256 _taskId) {
        IProject _projectInstance = IProject(_project);
        (, , address _sc, , , , , ) = (_projectInstance.tasks(_taskId));
        require(
            _projectInstance.contractor() == msg.sender ||
                _projectInstance.builder() == msg.sender ||
                _sc == msg.sender,
            "Invalid Member of project"
        );
        _;
    }

    modifier onlyAdmin() {
        require(padlock.hasRole(0x00, msg.sender) == true, "Only admin");
        _;
    }

    function raiseDispute(
        bytes calldata _reasonHash,
        address _project,
        uint256 _taskId
    ) external onlyMember(_project, _taskId) {
        disputeCount++;
        disputes[disputeCount].status = Status.Active;
        disputes[disputeCount].reasonHash = _reasonHash;
        disputes[disputeCount].project = _project;
        disputes[disputeCount].taskId = _taskId;
        disputes[disputeCount].raisedBy = msg.sender;
        eventsInstance.disputeRaised(
            msg.sender,
            _project,
            _taskId,
            disputeCount
        );
    }

    function addDocuments(
        bytes calldata _reasonHash,
        uint256 _disputeNo
    ) external {
        address _project = disputes[_disputeNo].project;
        uint256 _taskId  = disputes[_disputeNo].taskId;
         IProject _projectInstance = IProject(_project);
        (, , address _sc, , , , , ) = (_projectInstance.tasks(_taskId));
        require(
            _projectInstance.contractor() == msg.sender ||
                _projectInstance.builder() == msg.sender ||
                _sc == msg.sender,
            "Invalid Member of project"
        );
        disputes[_disputeNo].otherBytes[msg.sender] = _reasonHash;
    }

    function resolveDispute(
        uint256 _disputeId,
        bytes calldata _resultHash,
        uint256 _result
    ) external onlyAdmin {
        disputes[_disputeId].status = Status(_result);
        disputes[_disputeId].resultHash = _resultHash;
        eventsInstance.disputeResolved(_disputeId, _result, _resultHash);
    }
}
