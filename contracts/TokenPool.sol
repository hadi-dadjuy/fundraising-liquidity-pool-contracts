// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./access/Ownable.sol";
import {IERC20} from "./token/IERC20.sol";
import {SafeMath} from "./utils/SafeMath.sol";
import {ABDKMathQuad as ABDKMath} from "./utils/ABDKMath.sol";
import "hardhat/console.sol";

contract TokenPool is Ownable {
    using SafeMath for uint256;
    uint256 public minDepositAmount = 1e18;
    uint256 public maxDepositAmount = 1e25;

    uint256 public currentRewardBalance;
    uint256 public currentAssetBalance;
    uint256 public currentCollateralBalance;

    uint256 immutable ASSET_BALANCE;
    uint256 immutable ASSET_REWARD_BALANCE;

    uint256 saleStartedAt;

    IERC20 collateral;
    IERC20 asset;

    uint32 immutable NUMBER_OF_EPOCHS;
    uint32 immutable EPOCH_PERIOD; // in seconds
    SaleStatus saleStatus;
    enum UserStatus {
        NOT_DEPOSITED,
        DEPOSITD,
        CLAIMED
    }

    enum SaleStatus {
        NOT_STARTED,
        STARTED,
        ENDED
    }
    struct User {
        uint256 deposited;
        uint256 depositedAt;
        uint32 epochNumber;
        UserStatus userStatus;
    }

    mapping(address => User) user;

    event SaleStarted(
        uint256 indexed startedAt,
        IERC20 indexed collateralToken,
        IERC20 indexed assetToken
    );
    event SaleEnded(
        uint256 indexed endedAt,
        IERC20 indexed collateralToken,
        IERC20 indexed assetToken
    );
    event Deposit(address indexed from, uint256 indexed amount);
    event Withdrawal(address indexed fromS, address indexed to, uint256 amount);
    event Claim(
        address indexed claimer,
        uint256 indexed amount,
        uint256 indexed reward
    );

    constructor(
        address collateralTokenAddress,
        address assetTokenAddress,
        uint256 assetBalance,
        uint256 assetRewardBalance,
        uint32 numberOfEpochs,
        uint32 epochPeriod
    ) {
        collateral = IERC20(collateralTokenAddress);
        asset = IERC20(assetTokenAddress);
        ASSET_BALANCE = assetBalance;
        ASSET_REWARD_BALANCE = assetRewardBalance;
        if (numberOfEpochs == 0 || epochPeriod == 0) {
            revert("TokenPool: invalid input");
        }
        currentAssetBalance = ASSET_BALANCE;
        currentRewardBalance = ASSET_REWARD_BALANCE;
        NUMBER_OF_EPOCHS = numberOfEpochs;
        EPOCH_PERIOD = epochPeriod;
        startSale();
    }

    function claim()
        external
        saleEnded
        userDeposited
        returns (uint256, uint256)
    {
        user[msg.sender].userStatus = UserStatus.CLAIMED;
        uint256 tokensCount = getTokens();
        currentAssetBalance = currentAssetBalance.sub(tokensCount);
        uint256 rewardsCount = getRewards();
        currentRewardBalance = currentRewardBalance.sub(rewardsCount);
        uint256 sum = SafeMath.add(tokensCount, rewardsCount);
        assert(sum > 0);
        require(asset.transfer(msg.sender, sum), "Unsuccessful transfer");
        emit Claim(msg.sender, tokensCount, rewardsCount);
        return (tokensCount, rewardsCount);
    }

    function getClaimAmount() external view returns (uint256, uint256) {
        if (user[msg.sender].userStatus == UserStatus.NOT_DEPOSITED) {
            return (0, 0);
        }
        return (getTokens(), getRewards());
    }

    function getRewards() public view returns (uint256) {
        uint256 numerator = SafeMath.mul(
            user[msg.sender].deposited,
            ASSET_REWARD_BALANCE
        );

        uint256 denominator = SafeMath.mul(
            SafeMath.add(user[msg.sender].epochNumber, 1),
            currentCollateralBalance
        );
        uint256 result = ABDKMath.toUInt(
            ABDKMath.div(
                ABDKMath.fromUInt(numerator),
                ABDKMath.fromUInt(denominator)
            )
        );

        return result;
    }

    function getTokens() public view returns (uint256) {
        uint256 result = SafeMath.mul(
            ABDKMath.toUInt(
                ABDKMath.div(
                    ABDKMath.fromUInt(ASSET_BALANCE),
                    ABDKMath.fromUInt(currentCollateralBalance)
                )
            ),
            user[msg.sender].deposited
        );
        if (result == 0) {
            return 1;
        }
        return result;
    }

    function deposit(uint256 amount)
        external
        saleStarted
        validateDeposit(amount)
        returns (bool)
    {
        if (!transfer(amount)) {
            return false;
        }
        uint32 currentEpoch = getCurrentEpoch();
        currentCollateralBalance = SafeMath.add(
            currentCollateralBalance,
            amount
        );

        User memory _user = User({
            deposited: amount,
            depositedAt: block.timestamp,
            epochNumber: currentEpoch,
            userStatus: UserStatus.DEPOSITD
        });
        user[msg.sender] = _user;
        emit Deposit(msg.sender, amount);
        return true;
    }

    function getUserInfo() external view returns (User memory) {
        return user[msg.sender];
    }

    function transfer(uint256 amount) private returns (bool) {
        require(
            collateral.transferFrom(msg.sender, address(this), amount),
            "TokenPool: unsuccessful transfer to contract"
        );
        return true;
    }

    function getCurrentEpoch() public view saleStarted returns (uint32) {
        uint256 salePeriod = SafeMath.mul(NUMBER_OF_EPOCHS, EPOCH_PERIOD);
        uint256 passedTime = SafeMath.sub(block.timestamp, saleStartedAt);
        if (passedTime > salePeriod) {
            revert("TokenPool: sale has ended");
        }
        return uint32(SafeMath.div(passedTime, EPOCH_PERIOD));
    }

    function getSaleRemainingTime() public view returns (uint256) {
        uint256 salePeriod = SafeMath.mul(NUMBER_OF_EPOCHS, EPOCH_PERIOD);
        uint256 passedTime = SafeMath.sub(block.timestamp, saleStartedAt);
        if (passedTime > salePeriod) {
            return 0;
        }
        return SafeMath.sub(salePeriod, passedTime);
    }

    function withdraw(address owner) external onlyOwner returns (bool) {
        if (endSale()) {
            require(
                collateral.transfer(owner, currentCollateralBalance),
                "TokenPool: unsuccessful transfer"
            );
            emit Withdrawal(msg.sender, owner, currentCollateralBalance);
            return true;
        }
        return false;
    }

    function startSale() private onlyOwner saleNotStarted returns (bool) {
        saleStartedAt = uint256(block.timestamp);
        saleStatus = SaleStatus.STARTED;
        emit SaleStarted(uint256(block.timestamp), collateral, asset);
        return true;
    }

    function endSale() public returns (bool) {
        uint256 salePeriod = SafeMath.mul(NUMBER_OF_EPOCHS, EPOCH_PERIOD);
        uint256 passedTime = SafeMath.sub(
            uint256(block.timestamp),
            saleStartedAt
        );
        if (passedTime > salePeriod) {
            saleStatus = SaleStatus.ENDED;
            return true;
        }
        return false;
    }

    function getTotalNumberOfEpochs() public view returns (uint32) {
        return NUMBER_OF_EPOCHS;
    }

    function setMinDepositAmount(uint256 value) external onlyOwner {
        minDepositAmount = value;
    }

    function setMaxDepositAmount(uint256 value) external onlyOwner {
        maxDepositAmount = value;
    }

    function getAssetBalance() external view returns (uint256) {
        return ASSET_BALANCE;
    }

    function getAssetRewardBalance() external view returns (uint256) {
        return ASSET_REWARD_BALANCE;
    }

    modifier saleNotStarted() {
        require(
            saleStatus == SaleStatus.NOT_STARTED,
            "TokenPool: sale status is not in NOT_STARTED state"
        );
        _;
    }

    modifier saleStarted() {
        require(
            saleStatus == SaleStatus.STARTED,
            "TokenPool: sale status is not in STARTED state"
        );
        _;
    }
    modifier saleEnded() {
        require(
            saleStatus == SaleStatus.ENDED,
            "TokenPool: sale status is not in ENDED state"
        );
        _;
    }

    modifier assetsTransfered() {
        require(
            asset.balanceOf(address(this)) >=
                SafeMath.add(ASSET_BALANCE, ASSET_REWARD_BALANCE),
            "TokenPool: assets not transfered to this contract"
        );
        _;
    }
    modifier userDeposited() {
        require(user[msg.sender].userStatus == UserStatus.DEPOSITD);
        _;
    }

    modifier validateDeposit(uint256 amount) {
        require(
            user[msg.sender].userStatus == UserStatus.NOT_DEPOSITED,
            "TokenPool: user has already depoisted"
        );
        require(
            amount >= minDepositAmount && amount <= maxDepositAmount,
            "TokenPool: amount is not in the accepted range"
        );
        _;
    }
}
