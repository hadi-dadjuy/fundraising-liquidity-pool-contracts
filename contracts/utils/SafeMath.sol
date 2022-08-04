// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function inc(uint256 a) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + 1;
            require(c >= a, "ERROR: Overflow occured!");
            return c;
        }
    }

    function dec(uint256 a) internal pure returns (uint256) {
        unchecked {
            require(a >= 1, "ERROR: Underflow occured!");
            return a - 1;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            require(c >= a, "ERROR: Overflow occured!");
            return c;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(a >= b, "ERROR: Underflow occured!");
            return a - b;
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (a == 0 || b == 0) {
                return 0;
            }
            uint256 c = a * b;
            require(c / a == b, "ERROR: Overflow occured!");
            return c;
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, "ERROR: Division by zero!");
            return a / b;
        }
    }

    function mode(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, "ERROR: Division by zero!");
            return a % b;
        }
    }
}
