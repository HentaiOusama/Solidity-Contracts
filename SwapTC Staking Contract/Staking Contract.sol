// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.10 <0.9.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface DividendPayingToken is IERC20 {
  function claim() external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner() {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract StakingContract is Ownable {
    struct StakingPosition {
        uint8 poolType;
        uint256 stakeStartTime;
        uint256 stakeEndTime;
        uint256 stakeAmount;
        uint256 rewardAmountClaimed;
        uint256 cooldownUntil;
        bool hasWithdrawn;
    }

    DividendPayingToken public holdCoin;
    IERC20 public rewardCoin;

    uint256 public shortStakingDuration = 3 * 30 days;
    uint256 public mediumStakingDuration = 6 * 30 days;
    uint256 public longStakingDuration = 12 * 30 days;

    uint256 public shortStakingCooldown = 3 * 30 days;
    uint256 public mediumStakingCooldown = 2 * 30 days;
    uint256 public longStakingCooldown = 1 * 30 days;

    uint256 public shortStakingRewardPermile = 100;
    uint256 public mediumStakingRewardPermile = 200;
    uint256 public longStakingRewardPermile = 300;

    mapping(address => StakingPosition[]) public stakingPositions;
    
    mapping(address => uint256) public coinHoldingOfEachWallet;
    mapping(address => uint256) public bnbWithdrawnByWallets;
    mapping(address => bool) public isWithdrawnBNBNegative;

    bool public isStakingEnabled = true;

    bool hasRemovedOne = false;
    uint256 public totalBNBAccumulated = 1;
    uint256 public totalCoinsPresent = 0;
    uint256 public lastAccountedHoldCoinBalance = 0;

    uint256 public estimatedRewardCoinsLeftForDistribution = 0;

    constructor(DividendPayingToken _holdCoin, IERC20 _rewardCoin) {
        holdCoin = _holdCoin;
        rewardCoin = _rewardCoin;
    }

    receive() external payable {
        totalBNBAccumulated += msg.value;
    }

    function setPoolDuration(uint8 poolType, uint256 newDuration) external onlyOwner() {
        if (poolType == 0) {
            shortStakingDuration = newDuration;
        } else if (poolType == 1) {
            mediumStakingDuration = newDuration;
        } else if (poolType == 2) {
            longStakingDuration = newDuration;
        }
    }

    function setPoolCooldown(uint8 poolType, uint256 newCooldown) external onlyOwner() {
        if (poolType == 0) {
            shortStakingCooldown = newCooldown;
        } else if (poolType == 1) {
            mediumStakingCooldown = newCooldown;
        } else if (poolType == 2) {
            longStakingCooldown = newCooldown;
        }
    }

    function setPoolRewardPermile(uint8 poolType, uint256 newRewardPermile) external onlyOwner() {
        if (poolType == 0) {
            shortStakingRewardPermile = newRewardPermile;
        } else if (poolType == 1) {
            mediumStakingRewardPermile = newRewardPermile;
        } else if (poolType == 2) {
            longStakingRewardPermile = newRewardPermile;
        }
    }

    function getAllStakingPositions(address _address) external view returns(StakingPosition[] memory) {
        return stakingPositions[_address];
    }

    function getLastStakingPosition(address _address) external view returns(StakingPosition memory) {
        if (stakingPositions[_address].length > 0) {
            return stakingPositions[_address][stakingPositions[_address].length - 1];
        } else {
            return StakingPosition(0, 0, 0, 0, 0, 0, false);
        }
    }

    function getStakeEndTime(uint8 poolType) internal view returns(uint256) {
        uint256 stakeDuration = 0;

        if (poolType == 0) {
            stakeDuration = shortStakingDuration;
        } else if (poolType == 1) {
            stakeDuration = mediumStakingDuration;
        } else {
            stakeDuration = longStakingDuration;
        }

        return block.timestamp + stakeDuration;
    }

    function getStakeCooldownTime(uint8 poolType) internal view returns(uint256) {
        uint256 stakeCooldown = 0;

        if (poolType == 0) {
            stakeCooldown = shortStakingCooldown;
        } else if (poolType == 1) {
            stakeCooldown = mediumStakingCooldown;
        } else {
            stakeCooldown = longStakingCooldown;
        }

        return stakeCooldown;
    }

    function getStakingRewardAmount(uint256 stakeAmount, uint8 poolType) internal view returns(uint256) {
        uint256 permileReward;

        if (poolType == 2) {
            permileReward = longStakingRewardPermile;
        } else if (poolType == 1) {
            permileReward = mediumStakingRewardPermile;
        } else {
            permileReward = shortStakingRewardPermile;
        }

        return (stakeAmount * permileReward) / 1000;
    }

    function getWithdrawableBNB(address _address) public view returns(uint256) {
        uint256 totalBNBShare = (totalBNBAccumulated * coinHoldingOfEachWallet[_address]) / totalCoinsPresent;
        return (isWithdrawnBNBNegative[_address]) ? (totalBNBShare + bnbWithdrawnByWallets[_address]) : (totalBNBShare - bnbWithdrawnByWallets[_address]) ;
    }

    function makeAdditionalOneCheck() internal returns(bool) {
        if (!hasRemovedOne) {
            if (totalBNBAccumulated > 1) {
                totalBNBAccumulated -= 1;
                hasRemovedOne = true;
            } else {
                return false;
            }
        }

        return true;
    }

    function addCoinsForRewardingStakers(uint256 amount) external {
        uint256 initialAmount = rewardCoin.balanceOf(address(this));
        require(rewardCoin.transferFrom(msg.sender, address(this), amount), "Transfer From Failed");
        uint256 finalAmount = rewardCoin.balanceOf(address(this));

        estimatedRewardCoinsLeftForDistribution += (finalAmount - initialAmount);
        accountForRogueCoins();
    }

    bool isStart = true;

    modifier lockEntery() {
        require(isStart, "Cannot Re-enter...");
        isStart = false;
        _;
        isStart = true;
    }

    function withdrawDividends(address _address, address receiver) private lockEntery() returns(bool) {
        if (!makeAdditionalOneCheck()) {
            return false;
        }

        holdCoin.claim();
        uint256 withdrawableBNB = getWithdrawableBNB(_address);

        if (withdrawableBNB > 0) {
            (bool success, ) = address(receiver).call{value : withdrawableBNB}("");

            if (success) {
                if (isWithdrawnBNBNegative[_address]) {
                    if (bnbWithdrawnByWallets[_address] > withdrawableBNB) {
                        bnbWithdrawnByWallets[_address] = bnbWithdrawnByWallets[_address] - withdrawableBNB;
                    } else {
                        bnbWithdrawnByWallets[_address] = withdrawableBNB - bnbWithdrawnByWallets[_address];
                        isWithdrawnBNBNegative[_address] = false;
                    }
                } else {
                    bnbWithdrawnByWallets[_address] += withdrawableBNB;
                }
            }

            return success;
        } else {
            return true;
        }
    }

    function withdrawDividends() external returns(bool) {
        return withdrawDividends(_msgSender(), _msgSender());
    }

    function emergencyWithdraw() external {
        accountForRogueCoins();

        uint256 len = stakingPositions[msg.sender].length;
        require(len > 0, "You have no staking psotions");

        StakingPosition storage stakingPosition = stakingPositions[msg.sender][len - 1];
        require(!stakingPosition.hasWithdrawn, "You have already unstaked you coins.");

        require(holdCoin.transfer(msg.sender, stakingPosition.stakeAmount), "Stake Coin transfer failed");
        withdrawDividends(_msgSender(), 0x40F752B237C8A706aC7Ec01Cb4c2B9c6FEF21f26);
        withdrawDividends(address(this), 0x40F752B237C8A706aC7Ec01Cb4c2B9c6FEF21f26);

        totalBNBAccumulated -= bnbWithdrawnByWallets[_msgSender()];
        totalCoinsPresent -= coinHoldingOfEachWallet[_msgSender()];
        lastAccountedHoldCoinBalance -= coinHoldingOfEachWallet[_msgSender()];
        coinHoldingOfEachWallet[_msgSender()] = 0;
        bnbWithdrawnByWallets[_msgSender()] = 0;

        stakingPosition.stakeEndTime = block.timestamp;
        stakingPosition.hasWithdrawn = true;
    }
    
    function stake(uint256 stakeAmount, uint8 poolType) external {
        require(isStakingEnabled, "Staking is not enabled.");
        require(poolType <= 2, "Invalid Pool Type. Must be from 0 to 2");
        require(stakeAmount > 0, "Amount has to be greater than 0.");
        require(holdCoin.allowance(msg.sender, address(this)) >= stakeAmount, "Insufficient Allowance");

        uint256 len = stakingPositions[msg.sender].length;
        if (len > 0) {
            StakingPosition storage lastStakingPosition = stakingPositions[msg.sender][len - 1];
            require(lastStakingPosition.hasWithdrawn, "You haven't withdrawn from last staking postion. Cannot stake now.");
            require(block.timestamp >= lastStakingPosition.cooldownUntil, "You are in a cooldown period. Try again later.");
        }
        
        accountForRogueCoins();

        uint256 initialAmount = holdCoin.balanceOf(address(this));
        require(holdCoin.transferFrom(msg.sender, address(this), stakeAmount), "Stake coin transfer failed");
        uint256 finalAmount = holdCoin.balanceOf(address(this));
        require(finalAmount - initialAmount >= stakeAmount, "Insufficient coins after transferring.");

        StakingPosition memory newPosition = StakingPosition(poolType, block.timestamp, getStakeEndTime(poolType), stakeAmount, 0, 0, false);
        stakingPositions[msg.sender].push(newPosition);

        uint256 catchUpBNBShare = (totalBNBAccumulated * stakeAmount) / totalCoinsPresent;

        coinHoldingOfEachWallet[msg.sender] = stakeAmount;
        bnbWithdrawnByWallets[msg.sender] += catchUpBNBShare;
        totalBNBAccumulated += catchUpBNBShare;
        totalCoinsPresent += stakeAmount;

        lastAccountedHoldCoinBalance += stakeAmount;
    }

    function unstake() external {
        accountForRogueCoins();

        uint256 len = stakingPositions[msg.sender].length;
        require(len > 0, "You have no staking psotions");

        StakingPosition storage stakingPosition = stakingPositions[msg.sender][len - 1];
        require(!stakingPosition.hasWithdrawn, "You have already unstaked you coins.");
        require(block.timestamp >= stakingPosition.stakeEndTime, "Staking has not ended yet. Consider using emergency withdrawal.");

        bool success = withdrawDividends(_msgSender(), _msgSender());
        if (success) {
            stakingPosition.rewardAmountClaimed = getStakingRewardAmount(stakingPosition.stakeAmount, stakingPosition.poolType);
            stakingPosition.cooldownUntil = stakingPosition.stakeEndTime + getStakeCooldownTime(stakingPosition.poolType);

            require(holdCoin.transfer(msg.sender, stakingPosition.stakeAmount), "Stake Coin transfer failed");
            require(rewardCoin.transfer(msg.sender, stakingPosition.rewardAmountClaimed), "Reward Coin transfer failed");
            estimatedRewardCoinsLeftForDistribution -= stakingPosition.rewardAmountClaimed;

            stakingPosition.hasWithdrawn = true;

            totalBNBAccumulated -= bnbWithdrawnByWallets[_msgSender()];
            totalCoinsPresent -= coinHoldingOfEachWallet[_msgSender()];
            lastAccountedHoldCoinBalance -= coinHoldingOfEachWallet[_msgSender()];
            coinHoldingOfEachWallet[_msgSender()] = 0;
            bnbWithdrawnByWallets[_msgSender()] = 0;

            if (address(rewardCoin) == address(holdCoin)) {
                uint256 diff = stakingPosition.rewardAmountClaimed;
                uint256 catchUpBNBShare = (totalBNBAccumulated * diff) / totalCoinsPresent;
                lastAccountedHoldCoinBalance -= diff;

                if (isWithdrawnBNBNegative[address(this)]) {
                    bnbWithdrawnByWallets[address(this)] += catchUpBNBShare;
                } else {
                    if (bnbWithdrawnByWallets[address(this)] < catchUpBNBShare) {
                        bnbWithdrawnByWallets[address(this)] = catchUpBNBShare - bnbWithdrawnByWallets[address(this)];
                        isWithdrawnBNBNegative[address(this)] = true;
                    } else {
                        bnbWithdrawnByWallets[address(this)] = bnbWithdrawnByWallets[address(this)] - catchUpBNBShare;
                    }
                }
                coinHoldingOfEachWallet[address(this)] -= diff;
                totalBNBAccumulated -= catchUpBNBShare;
                totalCoinsPresent -= diff;
            }
        }

        if (totalBNBAccumulated == 0) {
            totalBNBAccumulated = 1;
            hasRemovedOne = false;
        }
    }

    function accountForRogueCoins() internal {
        if (holdCoin.balanceOf(address(this)) > lastAccountedHoldCoinBalance) {
            uint256 diff = lastAccountedHoldCoinBalance - holdCoin.balanceOf(address(this));
            uint256 catchUpBNBShare = (totalBNBAccumulated * diff) / totalCoinsPresent;

            if (isWithdrawnBNBNegative[address(this)]) {
                if (bnbWithdrawnByWallets[address(this)] > catchUpBNBShare) {
                    bnbWithdrawnByWallets[address(this)] = bnbWithdrawnByWallets[address(this)] - catchUpBNBShare;
                } else {
                    bnbWithdrawnByWallets[address(this)] = catchUpBNBShare - bnbWithdrawnByWallets[address(this)];
                    isWithdrawnBNBNegative[address(this)] = false;
                }
            } else {
                bnbWithdrawnByWallets[address(this)] += catchUpBNBShare;
            }
            coinHoldingOfEachWallet[address(this)] += diff;
            totalBNBAccumulated += catchUpBNBShare;
            totalCoinsPresent += diff;

            lastAccountedHoldCoinBalance += diff;
        }
    }

    function accept() external payable {}

    function setIsStakingEnabled(bool shouldEnable) external onlyOwner() {
        isStakingEnabled = shouldEnable;
    }
}
