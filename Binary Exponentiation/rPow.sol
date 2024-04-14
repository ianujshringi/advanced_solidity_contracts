// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AssemblyRPow {
    function getRPow(
        uint256 x,
        uint256 n,
        uint256 b
    ) public pure returns (uint256 z) {
        assembly {
            switch x
            // x == 0
            case 0 {
                switch n
                case 0 {
                    z := b
                }
                default {
                    z := 0
                }
            }
            // x != 0
            default {
                // algo
                switch mod(n, 2)
                // n is even ---> z = 1*b
                case 0 {
                    z := b
                }
                // n is odd ---> z = x
                default {
                    z := x
                }
                let half := div(b, 2)

                // n = n/2 while n > 0 , n /= 2
                for {
                    n := div(n, 2)
                } gt(n, 0) {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)

                    // overflow check
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }

                    let xxRound := add(xx, half)

                    x := div(xxRound, b)

                    if mod(n, 2) {
                        let zx := mul(z, x)

                        // overflow check
                        if and(iszero(iszero(x)), iszero(eq(div(zx, z), x))) {
                            revert(0, 0)
                        }

                        // rounding
                        let zxRound := add(zx, half)

                        z := div(zxRound, b)
                    }
                }
            }
        }
    }
}
