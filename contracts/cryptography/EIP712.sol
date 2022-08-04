// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "./ECDSA.sol";

abstract contract EIP712 {
    bytes32 internal immutable EIP712_DOMAIN_SEPERATOR_TYPE_HASH;

    constructor(string memory name, string memory version) {
        EIP712_DOMAIN_SEPERATOR_TYPE_HASH = ECDSA._hashEIP712DomainSeperator(
            name,
            version
        );
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function hashEIP712Message(bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        return
            ECDSA._hashEIP712Message(
                EIP712_DOMAIN_SEPERATOR_TYPE_HASH,
                structHash
            );
    }
}
