// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed transactionId);
    event Approve(address indexed owner, uint256 indexed transactionId);
    event Revoke(address indexed owner, uint256 indexed transactionId);
    event Execute(uint256 indexed transactionId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not owner!");
        _;
    }

    modifier transactionExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist!");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Transaction already approved!");
        _;
    }

    modifier isApproved(uint256 _txId) {
        require(approved[_txId][msg.sender], "Transaction not approved!");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "No owners specified!");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid Required Approvals!"
        );
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner address!");
            require(!isOwner[owner], "Owner is not unique!");
            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredApprovals = _requiredApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txId)
        external
        onlyOwner
        transactionExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) count += 1;
        }
    }

    function execute(uint256 _txId)
        external
        transactionExists(_txId)
        notExecuted(_txId)
    {
        require(
            _getApprovalCount(_txId) >= requiredApprovals,
            "Not enough approvals!"
        );
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed!");
        emit Execute(_txId);
    }

    function revoke(uint256 _txId)
        external
        onlyOwner
        transactionExists(_txId)
        isApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
