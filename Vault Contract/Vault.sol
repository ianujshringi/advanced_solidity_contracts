// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ERC20 Token/IERC20.sol";

contract Vault {
    IERC20 public immutable token;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function _mint(address _to, uint256 _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    function deposit(uint256 _amount) external {
        /*  let
            a = amount of shares
            b = balance of token before deposit
            t = total supply
            s = shares to mint

            then
            (t+s)/t = (a+b)/b
            s = at/b
        */

        uint256 shares = totalSupply == 0
            ? _amount
            : (_amount * totalSupply) / token.balanceOf((address(this)));

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _shares) external {
        /*  let
            a = amount of shares
            b = balance of token before withdraw
            t = total supply
            s = shares to burn

            then
            (t-s)/t = (b-a)/b
            a = sb/t
        */
        uint256 amount = (_shares * token.balanceOf(address(this))) /
            totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
    }
}
