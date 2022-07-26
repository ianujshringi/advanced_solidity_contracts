// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TimeLock {
    address public owner;
    mapping(bytes32 => bool) queued;

    uint256 public constant MIN_DELAY = 10; //10Sec
    uint256 public constant MAX_DELAY = 1000; // 1000Sec
    uint256 public constant GRACE_PERIOD = 1000; // 1000Sec

    error NotOwner();
    error QueuedError(bytes32 txId);
    error TimeStampNotInRange(uint256 timestamp, uint256 currentTimestamp);
    error TimestampNotPassed(uint256 timestamp, uint256 currentTimestamp);
    error TimestampExpired(uint256 expiresAt, uint256 currentTimestamp);
    error NotQueued(bytes32 txId);
    error TxFailed(bytes32 txId);

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint256 value,
        string func,
        bytes data,
        uint256 timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint256 value,
        string func,
        bytes data,
        uint256 timestamp
    );
    event Cancel(bytes32 indexed txId);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function getTxId(
        address _target,
        uint256 _value,
        string calldata _function,
        bytes calldata _data,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_target, _value, _function, _data, _timestamp)
            );
    }

    function queue(
        address _target,
        uint256 _value,
        string calldata _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external onlyOwner {
        // creating transaction Id
        bytes32 txId = getTxId(_target, _value, _function, _data, _timestamp);
        if (queued[txId]) revert QueuedError(txId);
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) revert TimeStampNotInRange(_timestamp, block.timestamp);
        queued[txId] = true;
        emit Queue(txId, _target, _value, _function, _data, _timestamp);
    }

    function execute(
        address _target,
        uint256 _value,
        string calldata _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _function, _data, _timestamp);
        if (!queued[txId]) revert NotQueued(txId);
        if (block.timestamp < _timestamp)
            revert TimestampNotPassed(_timestamp, block.timestamp);
        if (block.timestamp > _timestamp + GRACE_PERIOD)
            revert TimestampExpired(_timestamp + GRACE_PERIOD, block.timestamp);
        queued[txId] = false;

        bytes memory data;
        if (bytes(_function).length > 0)
            data = abi.encodePacked(bytes4(keccak256(bytes(_function))), _data);
        else data = _data;
        // execute the transaction
        (bool success, bytes memory result) = _target.call{value: _value}(data);
        if (!success) revert TxFailed(txId);

        emit Execute(txId, _target, _value, _function, _data, _timestamp);
        return result;
    }

    function cancel(bytes32 txId) external onlyOwner {
        if (!queued[txId]) revert NotQueued(txId);
        queued[txId] = false;
        emit Cancel(txId);
    }
}
