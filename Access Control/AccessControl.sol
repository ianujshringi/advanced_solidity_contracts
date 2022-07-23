// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    // role(hash) => account(address) => hasAccess(bool)
    mapping(bytes32 => mapping(address => bool)) private roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Sorry You are not authorized!");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function grantRole(string memory _role, address _account)
        external
        onlyRole(ADMIN)
    {
        if (keccak256(abi.encodePacked(_role)) == ADMIN)
            _grantRole(ADMIN, _account);
        else if (keccak256(abi.encodePacked(_role)) == USER)
            _grantRole(USER, _account);
        else revert("Role is not valid!");
    }

    function revokeRole(string memory _role, address _account)
        external
        onlyRole(ADMIN)
    {
        if (keccak256(abi.encodePacked(_role)) == ADMIN)
            _revokeRole(ADMIN, _account);
        else if (keccak256(abi.encodePacked(_role)) == USER)
            _revokeRole(USER, _account);
        else revert("Role is not valid!");
    }

    // Returns role name if assigned
    function getRole(address _account) external view returns (string memory) {
        if (roles[ADMIN][_account]) return "ADMIN";
        else if (roles[USER][_account]) return "USER";
        else revert("No Role Granted!");
    }
}
