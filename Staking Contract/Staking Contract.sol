// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RocketDropV1point5 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 subtractableReward; // Reward debt. See explanation below.
        uint256 depositStamp;
    }

    struct BasicPoolInfo {
        bool doesExists;
        bool hasEnded;
        IERC20 lpToken;                         // Address of LP token contract.
        uint256 rewardPerTokenStaked;           // Accumulated ERC20s per share, times 1e36.
        IERC20 rewardToken;                     // pool specific reward token.
        uint256 startBlock;                     // pool specific block number when rewards start
        uint256 rewardPerBlock;                 // pool specific reward per block
        uint256 gasAmount;                      // eth fee charged on deposits and withdrawals (per pool)
        uint256 minStake;                       // minimum tokens allowed to be staked
        uint256 maxStake;                       // max tokens allowed to be staked
        uint256 lpTokenFee;                     // divide by 1000 ie 150 is 1.5%
        uint256 lockPeriod;                     // time in blocks needed before withdrawal
    }

    struct DetailedPoolInfo {
        uint256 tokensStaked;                   // allows the same token to be staked across different pools
        uint256 paidOut;                        // total paid out by pool
        uint256 lastRewardBlock;                // Last block number that ERC20s distribution occurs.
        uint256 endBlock;                       // pool specific block number when rewards end
        uint256 maxStakers;
        uint256 totalStakers;
        mapping(address => UserInfo) userInfo;  // Info of each user that stakes LP tokens.
    }

    // default eth fee for deposits and withdrawals
    // uint256 public gasAmount = 2000000000000000;
    uint256 public gasAmount;
    address payable public treasury;

    // Stake Token => (Reward Token => (Pool Id => BasicPoolInfo))
    mapping(IERC20 => mapping(IERC20 => uint256)) public latestPoolNumber;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => BasicPoolInfo))) public allPoolsBasicInfo;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => DetailedPoolInfo))) public allPoolsDetailedInfo;

    event Deposit(address indexed user, IERC20 indexed lpToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event Withdraw(address indexed user, IERC20 indexed lpToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event EmergencyWithdraw(address indexed user, IERC20 indexed lpToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);

    constructor() {
        treasury = payable(msg.sender);
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    // function getPoolCount() external view returns (uint256) {
    //     return basicPoolInfo.length;
    // }


    // Add a new lp to the pool. Can only be called by the owner.
    // rewards are calculated per pool, so you can add the same lpToken multiple times
    function createNewStakingPool(IERC20 _lpToken, IERC20 _rewardToken, uint256 _rewardPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            // massUpdatePools();
        }

        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];
        require(!basicPoolInfo.doesExists, "This pool already exists.");
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];

        basicPoolInfo.doesExists = true;
        basicPoolInfo.lpToken = _lpToken;
        basicPoolInfo.rewardToken = _rewardToken;
        basicPoolInfo.rewardPerBlock = _rewardPerBlock;
        basicPoolInfo.gasAmount = gasAmount;
        basicPoolInfo.maxStake = ~uint256(0);
        detailedPoolInfo.maxStakers = ~uint256(0);
    }

    // Fund the pool, consequently setting the end block
    function performInitialFunding(IERC20 _lpToken, IERC20 _rewardToken, uint256 _amount, uint256 _startBlock) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];

        require(basicPoolInfo.doesExists, "performInitialFunding: No such pool exists.");
        require(basicPoolInfo.startBlock == 0, "performInitialFunding: Initial funding already complete");

        IERC20 erc20 = basicPoolInfo.rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        detailedPoolInfo.lastRewardBlock = _startBlock;
        basicPoolInfo.startBlock = _startBlock;
        detailedPoolInfo.endBlock = _startBlock.add(trueDepositedTokens.div(basicPoolInfo.rewardPerBlock));
    }

    // Increase the funds the pool, consequently increasing the end block
    function increasePoolFunding(IERC20 _lpToken, IERC20 _rewardToken, uint256 _amount) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];

        require(block.number < detailedPoolInfo.endBlock, "increasePoolFunding: Pool closed or perform initial funding first");

        IERC20 erc20 = basicPoolInfo.rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        detailedPoolInfo.endBlock += trueDepositedTokens.div(basicPoolInfo.rewardPerBlock);
    }

    function setPoolMaxStakers(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _maxStakers) public onlyOwner {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        require(basicPoolInfo.doesExists, "No such pool exists.");

        detailedPoolInfo.maxStakers = (_maxStakers < detailedPoolInfo.totalStakers) ? detailedPoolInfo.totalStakers : _maxStakers;
    }

    // View function to see LP amount staked by a user.
    function getUserStakedAmount(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, address _user) external view returns (uint256) {
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        return detailedPoolInfo.userInfo[_user].amount;
    }

    // View function to see pending rewards of a user.
    function getPendingRewardsOfUser(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, address _user) public view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[_user];
        uint256 rewardPerTokenStaked = basicPoolInfo.rewardPerTokenStaked;
        
        uint256 tokensStaked = detailedPoolInfo.tokensStaked;

        if (block.number > detailedPoolInfo.lastRewardBlock && tokensStaked != 0) {
            uint256 lastBlock = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
            uint256 noOfBlocks = lastBlock.sub(detailedPoolInfo.lastRewardBlock);
            uint256 erc20Reward = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);
            rewardPerTokenStaked = rewardPerTokenStaked.add(erc20Reward.mul(1e36).div(tokensStaked));
        }

        return user.amount.mul(rewardPerTokenStaked).div(1e36).sub(user.subtractableReward);
    }

    // View function for total reward the farm has yet to pay out.
    function getTotalPendingRewardsOfPool(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex) external view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        if (block.number <= basicPoolInfo.startBlock) {
            return 0;
        }

        uint256 elapsedBlockCount = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
        elapsedBlockCount = elapsedBlockCount.sub(basicPoolInfo.startBlock);

        return (basicPoolInfo.rewardPerBlock.mul(elapsedBlockCount)).sub(detailedPoolInfo.paidOut);
    }

    function getRewardPerBlockOfPool(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex) external view returns (uint) {
        return allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex].rewardPerBlock;
    }

    // TODO : Needs more updates...
    // Updates rewardPerTokenStaked and lastRewardBlock of the given pool.
    function updatePoolRewards(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        uint256 lastRewardBlock = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;

        if (lastRewardBlock > detailedPoolInfo.lastRewardBlock) {
            uint256 tokensStaked = detailedPoolInfo.tokensStaked;
            detailedPoolInfo.lastRewardBlock = lastRewardBlock;

            if (tokensStaked > 0) {
                uint256 noOfBlocks = lastRewardBlock.sub(detailedPoolInfo.lastRewardBlock);
                uint256 erc20Reward = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);

                basicPoolInfo.rewardPerTokenStaked = basicPoolInfo.rewardPerTokenStaked.add(erc20Reward.mul(1e36).div(tokensStaked));
                detailedPoolInfo.lastRewardBlock = lastRewardBlock;
            }
        }
    }

    // Deposit LP tokens to VendingMachine for ERC20 allocation.
    function stakeWithPool(IERC20 _lpToken, IERC20 _rewardToken, uint256 _amount) external payable {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][latestPoolNumber[_lpToken][_rewardToken]];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        require(detailedPoolInfo.totalStakers < detailedPoolInfo.maxStakers, "Max stakers reached!");

        require(msg.value >= basicPoolInfo.gasAmount, "Insufficient Value for the trx.");
        require(_amount >= basicPoolInfo.minStake && (_amount.add(user.amount)) <= basicPoolInfo.maxStake, "Stake amount out of range.");

        updatePoolRewards(_lpToken, _rewardToken, latestPoolNumber[_lpToken][_rewardToken]);
        if (user.amount > 0) {
            uint256 pendingAmount = getPendingRewardsOfUser(_lpToken, _rewardToken, latestPoolNumber[_lpToken][_rewardToken], msg.sender);
            if(pendingAmount > 0) {
                erc20RewardTransfer(msg.sender, _lpToken, _rewardToken, latestPoolNumber[_lpToken][_rewardToken], pendingAmount);
            }
        }

        uint256 startTokenBalance = basicPoolInfo.lpToken.balanceOf(address(this));
        basicPoolInfo.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = basicPoolInfo.lpToken.balanceOf(address(this));
        uint256 depositFee = basicPoolInfo.lpTokenFee.mul(endTokenBalance).div(1000);
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance).sub(depositFee);

        user.amount = user.amount.add(trueDepositedTokens);
        user.depositStamp = block.number;
        detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.add(trueDepositedTokens);
        user.subtractableReward = user.amount.mul(basicPoolInfo.rewardPerTokenStaked).div(1e36);
        
        treasury.transfer(msg.value);
        
        detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.add(1);

        emit Deposit(msg.sender, _lpToken, _rewardToken, latestPoolNumber[_lpToken][_rewardToken], _amount);
    }

    // Withdraw LP tokens from VendingMachine.
    function unstakeFromPool(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) public payable {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        require(basicPoolInfo.doesExists, "unstakeFromPool: No such pool exists.");
        require(msg.value >= basicPoolInfo.gasAmount, "Correct gas amount must be sent!");
        require(user.amount >= _amount, "unstakeFromPool: Can't withdraw more than deposit");
        
        if(_amount > 0) {
            require(user.depositStamp.add(basicPoolInfo.lockPeriod) <= block.number, "Lock period not fulfilled");
            basicPoolInfo.lpToken.safeTransfer(address(msg.sender), _amount);
            detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(_amount);
        }

        updatePoolRewards(_lpToken, _rewardToken, poolIndex);

        uint256 pendingAmount = getPendingRewardsOfUser(_lpToken, _rewardToken, poolIndex, msg.sender);
        if(pendingAmount > 0) {
            erc20RewardTransfer(msg.sender, _lpToken, _rewardToken, poolIndex, pendingAmount);
        }
        
        user.amount = user.amount.sub(_amount);
        user.subtractableReward = user.amount.mul(basicPoolInfo.rewardPerTokenStaked).div(1e36);

        treasury.transfer(msg.value);

        if(user.amount == 0) {
            detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);
        }
        emit Withdraw(msg.sender, _lpToken, _rewardToken, poolIndex, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        basicPoolInfo.lpToken.safeTransfer(address(msg.sender), user.amount);
        detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(user.amount);
        user.amount = 0;
        user.subtractableReward = 0;
        detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);

        emit EmergencyWithdraw(msg.sender, _lpToken, _rewardToken, poolIndex, user.amount);
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20RewardTransfer(address _to, IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) internal {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_lpToken][_rewardToken][poolIndex];
        IERC20 erc20 = basicPoolInfo.rewardToken;

        try erc20.transfer(_to, _amount) {
            detailedPoolInfo.paidOut = detailedPoolInfo.paidOut.add(_amount);
        } catch {} 
    }
    
    // Adjusts Gas Fee
    function adjustGasGlobal(uint256 newgas) public onlyOwner {
        gasAmount = newgas;
    }
    function adjustPoolGas(IERC20 _lpToken, IERC20 _rewardToken, uint256 poolIndex, uint256 newgas) public onlyOwner {
        allPoolsBasicInfo[_lpToken][_rewardToken][poolIndex].gasAmount = newgas;
    }

    // Treasury Management
    function changeTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }
    function transfer() public onlyOwner {
        treasury.transfer(address(this).balance);
    }
    
    // TODO : Update this function to make check for min. amount to protect pools.
    // function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
    //     IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
    //     return true;
    // }
}