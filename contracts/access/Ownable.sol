// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private owner;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function changeOwnership(address newOwner)
        external
        onlyOwner
        returns (bool)
    {
        owner = newOwner;
        emit OwnerChanged(msg.sender, newOwner);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR: Caller is not owner.");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "ERROR: Zero address is not allowed.");
        _;
    }
}
