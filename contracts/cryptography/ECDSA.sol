// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ECDSA {
    bytes32 internal constant EIP712_DOMAIN_SEPERATOR_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function _hashEIP712DomainSeperator(
        string memory name,
        string memory version
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    EIP712_DOMAIN_SEPERATOR_HASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashEIP712Message(
        bytes32 eip712DomainSeperatorHash,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901), // EIP191 header
                    eip712DomainSeperatorHash,
                    structHash
                )
            );
    }
}
