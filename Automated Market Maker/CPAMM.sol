// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ERC20 Token/IERC20.sol";

contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(address _tokenIn, uint256 _amountIn)
        external
        returns (uint256 amountOut)
    {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Invalid token!"
        );
        require(_amountIn > 0, "Enter valid amount!");

        bool isToken0 = _tokenIn == address(token0);
        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        /* 
            y = amount of tokenOut locked inside contract
            x = amount of tokenIn locked inside contract
            dx = amount of tokenIn came in
            dy = amount of tokenOut to go out
            ydx / (x+dx) = dy 
        */
        uint256 amountInWithFee = (_amountIn * 997) / 1000; //fee = 0.3%
        amountOut =
            (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);

        tokenOut.transfer(msg.sender, amountOut);

        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 shares)
    {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        /*
            y = amount of tokenOut locked inside contract
            x = amount of tokenIn locked inside contract
            dx = amount of tokenIn came in
            dy = amount of tokenOut to go out
            dy/dy= y/x
         */
        if (reserve0 > 0 || reserve1 > 0)
            require(
                reserve0 * _amount1 == reserve1 * _amount0,
                "Reserve != amount"
            );
        /*
                y = amount of tokenOut locked inside contract
                x = amount of tokenIn locked inside contract
                dx = amount of tokenIn came in
                dy = amount of tokenOut to go out
                s = amount of shares
                t = total supply
                f(x,y) = value of liquidity = sqrt(x*y)
                s = dx/x * t = dy/y *t
             */
        if (totalSupply == 0) shares = _sqrt(_amount0 * _amount1);
        else
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );

        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function _sqrt(uint256 x) private pure returns (uint256 res) {
        if (x > 3) {
            res = x;
            uint256 t = x / 2 + 1;
            while (t < res) {
                res = t;
                t = (x / t + t) / 2;
            }
        } else if (x != 0) {
            res = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    function removeLiquidity(uint256 _shares)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        /*  dx = amount of token0 that goes out
            dy = amount of token1 that goes out
            s = amount of shares
            t = total supply 
            x = amount of token0 locked inside contract
            y = amount of token1 locked inside contract
        */
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;

        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        _burn(msg.sender, _shares);
        _update(bal0 - amount0, bal1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }
}
