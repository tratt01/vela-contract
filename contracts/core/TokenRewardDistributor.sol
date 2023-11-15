// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../core/interfaces/IOperators.sol";

contract TokenRewardDistributor is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct RewardInfo {
        address account;
        uint256 amount;
    }

    IOperators public immutable operators;
    IERC20 public immutable rewardToken;

    mapping(address => uint256) public totalRewards;
    mapping(address => uint256) public claimedRewards;

    event ClaimReward(address indexed account, uint256 rewardAmount);

    modifier onlyOperator(uint256 level) {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
        _;
    }

    constructor(address _operators, address _rewardToken) {
        operators = IOperators(_operators);
        rewardToken = IERC20(_rewardToken);
    }

    function getClaimableReward(address _account) public view returns (uint256) {
        return totalRewards[_account] - claimedRewards[_account];
    }

    function claimReward() external nonReentrant {
        uint256 claimableReward = getClaimableReward(msg.sender);
        require(claimableReward > 0, "zero amount");

        claimedRewards[msg.sender] += claimableReward;

        rewardToken.safeTransfer(msg.sender, claimableReward);
        emit ClaimReward(msg.sender, claimableReward);
    }

    function addRewards(RewardInfo[] calldata _rewardInfos) external onlyOperator(3) {
        uint256 length = _rewardInfos.length;
        for (uint256 i; i < length; ) {
            totalRewards[_rewardInfos[i].account] += _rewardInfos[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    function setRewards(RewardInfo[] calldata _rewardInfos) external onlyOperator(3) {
        uint256 length = _rewardInfos.length;
        for (uint256 i; i < length; ) {
            totalRewards[_rewardInfos[i].account] = _rewardInfos[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    function rescueToken(address _token, uint256 _amount) external onlyOperator(4) {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}