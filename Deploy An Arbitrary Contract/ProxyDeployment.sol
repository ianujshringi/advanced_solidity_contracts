// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contract1 {
    address public owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}

contract Contract2 {
    address public owner = msg.sender;
    uint256 public value = msg.value;
    uint256 public x;
    uint256 public y;

    constructor(uint256 _x, uint256 _y) payable {
        x = _x;
        y = _y;
    }
}

contract Proxy {
    fallback() external payable {}

    receive() external payable {}

    event Deploy(address);

    function deploy(bytes memory _code)
        external
        payable
        returns (address addr)
    {
        assembly {
            // Have to use create(v,p,n) where,
            // v = amount of ETH to send
            // p = pointer in memory to start of the code
            //  n = size of the code
            addr := create(callvalue(), add(_code, 0x20), mload(_code)) // first 32 bytes are the length of code (0x20 is 32 bytes in hex)
        }
        require(addr != address(0), " Deployment Failed");
        emit Deploy(addr);
    }

    // For calling the function inside deployed contract
    function call(address _target, bytes memory _data) external payable {
        (bool success, ) = _target.call{value: msg.value}(_data);
        require(success, "Call Failed");
    }
}

// For the byte code extraction

contract Extractor {
    function getByteCode1() external pure returns (bytes memory bytecode) {
        bytecode = type(Contract1).creationCode;
    }

    function getByteCode(uint256 _x, uint256 _y)
        external
        pure
        returns (bytes memory bytecode)
    {
        bytecode = type(Contract2).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

    function getCalldata(address _owner) external pure returns (bytes memory) {
        return abi.encodeWithSignature("setOwner(address)", _owner);
    }
}
