// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The steps to verify the signature:
    1. message to sign
    2. hash(message)
    3. sign(hash(message), private_key) || offchain using a wallet
    4. ecrecover(hash(message), signature) == signer
*/

contract VerifySig {
    function verify(
        address _signer,
        string memory _message,
        bytes memory _sig
    ) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recover(ethSignedMessageHash, _sig) == _signer;
    }

    function getMessageHash(string memory _message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address signer)
    {
        (bytes32 r, bytes32 s, uint8 v) = split(_sig);
        signer = ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "Invalid signature length"); //r = 32bytes, s = 32bytes and v = 1(uint8 = 1byte). So total 65bytes
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}
