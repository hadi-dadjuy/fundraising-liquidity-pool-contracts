// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Permit} from "./IERC20Permit.sol";
import {EIP712} from "../cryptography/EIP712.sol";
import {ERC20} from "./ERC20.sol";
import {SafeMath} from "../utils/SafeMath.sol";

abstract contract ERC20Permit is IERC20Permit, ERC20, EIP712 {
    using SafeMath for uint256;
    mapping(address => uint256) nonce;
    bytes32 private constant PERMIT_TYPE_HASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    constructor(
        address ownerAccount,
        string memory _name,
        string memory _symbol
    )
        notZeroAddress(ownerAccount)
        ERC20(ownerAccount, _name, _symbol)
        EIP712(_name, "1")
    {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "ERC20Permit: deadline expired");

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPE_HASH,
                owner,
                spender,
                value,
                nonce[owner],
                deadline
            )
        );
        nonce[owner] = nonce[owner].inc();
        bytes32 hash = hashEIP712Message(structHash);
        address signer = EIP712.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }
}
