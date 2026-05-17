// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library YulMath {
    function sqrtSolidity(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 y = (x + 1) / 2;
        while (y < z) {
            z = y;
            y = (x / y + y) / 2;
        }
    }

    function sqrtYul(uint256 x) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 { z := 0 }
            default {
                z := x
                let y := div(add(x, 1), 2)
                for { } lt(y, z) { } {
                    z := y
                    y := div(add(div(x, y), y), 2)
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
