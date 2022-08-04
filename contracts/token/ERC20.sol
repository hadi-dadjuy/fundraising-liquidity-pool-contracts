// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {Ownable} from "../access/Ownable.sol";
import {SafeMath} from "../utils/SafeMath.sol";

contract ERC20 is Ownable, IERC20 {
    using SafeMath for uint256;
    // ERC20 storage
    string public name;
    string public symbol;
    uint256 public totalSupply = 1_000_000_000e18;
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor(
        address ownerAccount,
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        balances[ownerAccount] = totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    function transfer(address dst, uint256 amount)
        external
        enoughBalance(msg.sender, amount)
        returns (bool)
    {
        return _transferFrom(msg.sender, dst, amount);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    )
        external
        enoughApproval(src, msg.sender, amount)
        enoughBalance(src, amount)
        returns (bool)
    {
        return _transferFrom(src, dst, amount);
    }

    function _transferFrom(
        address src,
        address dst,
        uint256 amount
    ) internal notZeroAddress(src) notZeroAddress(dst) returns (bool) {
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal notZeroAddress(spender) returns (bool) {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    modifier notZeroAmount(uint256 amount) {
        require(amount != 0, "ERC20: Zero amount is not allowed.");
        _;
    }
    modifier enoughBalance(address account, uint256 expected) {
        require(balances[account] >= expected, "ERC20: Not enough balance.");
        _;
    }
    modifier enoughApproval(
        address owner,
        address spender,
        uint256 amount
    ) {
        require(
            allowances[owner][spender] >= amount,
            "ERC20: Not enough approval."
        );
        _;
    }
}
