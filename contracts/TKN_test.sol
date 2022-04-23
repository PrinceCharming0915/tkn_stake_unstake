pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract TKN_test is Ownable {
    bool TESTING = true;
    using SafeMath for uint256;

    // stakeToken address(TKN)
    // 0xaD6D458402F60fD3Bd25163575031ACDce07538D
    ERC20 public stakeToken;
    ERC20 public rewardToken;

    uint256 public maxStakeableToken;
    uint256 public minStakeableToken;
    uint256 public totalUnstakedToken;
    uint256 public totalStakedToken;
    uint256 public totalClaimedRewardToken;
    uint256 public totalStakers;
    uint256 public percentDivider;

    uint256 public duration = 20 seconds;

    struct Stake {
        uint256 unstakeTime;
        uint256 stakeTime;
        uint256 amount;
        uint256 reward;
        uint256 availableUnstakeAmount;
        uint256 availableUnClaimedReward;
        bool withdrawn;
        bool unstaked;
    }

    struct User {
        uint256 totalStakedToken;
        uint256 totalUnstakedToken;
        uint256 totalClaimedRewardToken;
        uint256 stakeCount;
        bool alreadyExists;
    }

    mapping(address => User) public Stakers;
    mapping(uint256 => address) public StakersID;
    mapping(address => mapping(uint256 => Stake)) public stakersRecord;


    constructor( address _stakingToken, address _rewardingToken ) {
        stakeToken = ERC20(_stakingToken);
        rewardToken = ERC20(_rewardingToken);
        maxStakeableToken = stakeToken.totalSupply();
        minStakeableToken = 1e13;
        percentDivider = 1e2;
    }

    function stake( uint256 _amount ) public {
        require(_amount >= minStakeableToken, "stake more than minimum amount");

        if ( !Stakers[msg.sender].alreadyExists ) {
            Stakers[msg.sender].alreadyExists = true;
            // StakersID.push(msg.sender);
            StakersID[totalStakers] = msg.sender;
            totalStakers ++;
        }

        stakeToken.transferFrom(msg.sender, address(this), _amount);

        uint256 index = Stakers[msg.sender].stakeCount;
        Stakers[msg.sender].totalStakedToken = Stakers[msg.sender]
            .totalStakedToken
            .add(_amount);

        totalStakedToken = totalStakedToken.add(_amount);

        stakersRecord[msg.sender][index].stakeTime = block.timestamp;
        stakersRecord[msg.sender][index].unstakeTime = block.timestamp.add(duration);

        stakersRecord[msg.sender][index].amount = _amount;
        stakersRecord[msg.sender][index].reward = getReward(_amount);

        stakersRecord[msg.sender][index].availableUnstakeAmount = _amount;
        stakersRecord[msg.sender][index].availableUnClaimedReward = getReward(_amount);

        stakersRecord[msg.sender][index].unstaked = false;
        stakersRecord[msg.sender][index].withdrawn = false;

        Stakers[msg.sender].stakeCount ++;
    }

    function unstake( uint256 _amount ) public {
        uint256 sendAmount = _amount;
        require( _amount <= getMaxUnstakeableAmount(msg.sender), "amount must be less than available max unstake amount" );
        for ( uint256 _index ; _index < Stakers[msg.sender].stakeCount ; _index++ ) {
            if ( stakersRecord[msg.sender][_index].unstaked || _amount == 0 ) {
                continue;
            }
            if ( stakersRecord[msg.sender][_index].unstakeTime >= block.timestamp ) {
                continue;
            }
            if ( stakersRecord[msg.sender][_index].availableUnstakeAmount > _amount ) {
                stakersRecord[msg.sender][_index].availableUnstakeAmount = stakersRecord[msg.sender][_index].availableUnstakeAmount - _amount;
                _amount = 0;
            } else {
                _amount = _amount - stakersRecord[msg.sender][_index].availableUnstakeAmount;
                stakersRecord[msg.sender][_index].availableUnstakeAmount = 0;
                stakersRecord[msg.sender][_index].unstaked = true;
            }
        }

        stakeToken.transfer(msg.sender, sendAmount);

        totalUnstakedToken = totalUnstakedToken.add(sendAmount);
        Stakers[msg.sender].totalUnstakedToken = Stakers[msg.sender].totalUnstakedToken.add(sendAmount);
    }

    function claim( uint256 _amount ) public {
        require( _amount <= getMaxUnclaimedAmount( msg.sender ), "amount must be less than available max uncliamed amount." );

        uint256 sendReward = _amount;

        for( uint256 _index ; _index < Stakers[msg.sender].stakeCount ; _index++ ) {
            if ( stakersRecord[msg.sender][_index].withdrawn || _amount == 0) {
                continue;
            }
            if ( stakersRecord[msg.sender][_index].unstakeTime >= block.timestamp ) {
                continue;
            }
            if ( stakersRecord[msg.sender][_index].availableUnClaimedReward > _amount ) {
                stakersRecord[msg.sender][_index].availableUnClaimedReward = stakersRecord[msg.sender][_index].availableUnClaimedReward - _amount;
                _amount = 0;
            } else {
                _amount = _amount - stakersRecord[msg.sender][_index].availableUnClaimedReward;
                stakersRecord[msg.sender][_index].availableUnClaimedReward = 0;
                stakersRecord[msg.sender][_index].withdrawn = true;
            }
        }

        rewardToken.transfer(msg.sender, sendReward);
        totalClaimedRewardToken = totalClaimedRewardToken.add(sendReward);
        Stakers[msg.sender].totalClaimedRewardToken = Stakers[msg.sender].totalClaimedRewardToken.add(sendReward);
    }

    function getMaxUnstakeableAmount( address _caller ) public view returns ( uint256 ) {
        uint256 maxUnstakeableAmount;
        for ( uint256 _index ; _index < Stakers[_caller].stakeCount ; _index++ ) {
            if ( !stakersRecord[_caller][_index].unstaked && stakersRecord[_caller][_index].unstakeTime < block.timestamp ) {
                maxUnstakeableAmount = maxUnstakeableAmount.add(stakersRecord[_caller][_index].availableUnstakeAmount);
            }
        }
        return maxUnstakeableAmount;
    }

    function getMaxUnclaimedAmount( address _caller ) public view returns ( uint256 ) {
        uint256 maxUnclaimedReward;
        for ( uint256 _index ; _index < Stakers[_caller].stakeCount ; _index++ ) {
            if ( !stakersRecord[_caller][_index].withdrawn && stakersRecord[_caller][_index].unstakeTime < block.timestamp ) {
                maxUnclaimedReward = maxUnclaimedReward.add( stakersRecord[_caller][_index].availableUnClaimedReward );
            }
        }
        return maxUnclaimedReward;
    }

    function getReward( uint _amount ) public view returns ( uint256 ) {
        return _amount.div(percentDivider);
    }

    function getTimeStamp() public view returns ( uint256 ) {
        return block.timestamp;
    }

    function getIndexStaker( uint256 _index ) public view returns ( address ) {
        return StakersID[_index];
    }

    function getIndexStakerUnstakedToken( address _index ) public view returns ( uint256 ) {
        return Stakers[_index].totalUnstakedToken;
    }

    function setStakeLimits( uint256 _min, uint256 _max ) external onlyOwner {
        minStakeableToken = _min;
        maxStakeableToken = _max;
    }

    function setStakeDuration( uint256 _duration ) external onlyOwner {
        duration = _duration;
    }
    
    function setPercentDivider( uint256 _percentDivider ) external onlyOwner {
        percentDivider = _percentDivider;
    }
}