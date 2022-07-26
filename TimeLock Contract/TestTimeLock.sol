// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TestTimeLock {
    address public timeLock;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    function test() external view {
        require(msg.sender == timeLock, "Not timelock!");
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp + 100;
    }
}
