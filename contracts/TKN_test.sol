/**
 *Submitted for verification at BscScan.com on 2021-12-06
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract TKN_test is Ownable {
    using SafeMath for uint256;

    // stakeToken address(TKN)
    // 0xaD6D458402F60fD3Bd25163575031ACDce07538D
    string public name = "TKN_test";

    ERC20 public stakeToken;
    ERC20 public rewardToken;

    uint256 public maxStakeableToken;
    uint256 public minStakeableToken;
    uint256 public totalUnStakedToken;
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
        uint256 availableUnstakedAmount;
        uint256 availableUnclaimedReward;
        bool withdrawn;
        bool unstaked;
    }

    struct User {
        uint256 totalStakedTokenUser;
        uint256 totalUnstakedTokenUser;
        uint256 totalClaimedRewardTokenUser;
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
            StakersID[totalStakers] = msg.sender;
            totalStakers ++;
        }

        stakeToken.transferFrom(msg.sender, address(this), _amount);

        uint256 index = Stakers[msg.sender].stakeCount;
        Stakers[msg.sender].totalStakedTokenUser = Stakers[msg.sender]
            .totalStakedTokenUser
            .add(_amount);

        totalStakedToken = totalStakedToken.add(_amount);

        stakersRecord[msg.sender][index].stakeTime = block.timestamp;
        stakersRecord[msg.sender][index].unstakeTime = block.timestamp.add(duration);

        stakersRecord[msg.sender][index].amount = _amount;
        stakersRecord[msg.sender][index].reward = _amount.div(percentDivider);

        stakersRecord[msg.sender][index].availableUnstakedAmount = _amount;
        stakersRecord[msg.sender][index].availableUnclaimedReward = _amount.div(percentDivider);

        stakersRecord[msg.sender][index].unstaked = false;
        stakersRecord[msg.sender][index].withdrawn = false;
            
        Stakers[msg.sender].stakeCount++;
    }

    function unstake( uint256 _amount ) public {
        require(
            _amount <= getMaxUnstakeAmount( msg.sender ),
            "amount must be less than available max unstake amount"
        );

        uint256 sendAmount = _amount;

        for (uint256 index; index < Stakers[msg.sender].stakeCount ; index++) {
            if (stakersRecord[msg.sender][index].unstaked || _amount == 0) {
                continue;
            }
            if ( stakersRecord[msg.sender][index].unstakeTime >= block.timestamp ) {
                continue;
            }
            if ( stakersRecord[msg.sender][index].availableUnstakedAmount > _amount ) {
                stakersRecord[msg.sender][index].availableUnstakedAmount =
                    stakersRecord[msg.sender][index].availableUnstakedAmount - _amount;
                _amount = 0;
            } else {
                _amount = _amount - stakersRecord[msg.sender][index].availableUnstakedAmount;
                stakersRecord[msg.sender][index].availableUnstakedAmount = 0;
                stakersRecord[msg.sender][index].unstaked = true;
            }
        }

        stakeToken.transfer(msg.sender, sendAmount);

        totalUnStakedToken = totalUnStakedToken.add(sendAmount);
        Stakers[msg.sender].totalUnstakedTokenUser = Stakers[msg.sender]
            .totalUnstakedTokenUser
            .add(sendAmount);
    }

    function claim( uint256 _amount ) public {
        require( _amount <= getMaxUncliamedAmount( msg.sender ), "amount must be less than available max claimed mount" );

        uint256 sendReward = _amount;

        for( uint256 index ; index < Stakers[msg.sender].stakeCount ; index++ ) {
            if ( stakersRecord[msg.sender][index].withdrawn || _amount == 0 ) {
                continue;
            }
            if ( stakersRecord[msg.sender][index].unstakeTime >= block.timestamp ) {
                continue;
            }
            if ( stakersRecord[msg.sender][index].availableUnclaimedReward > _amount ) {
                stakersRecord[msg.sender][index].availableUnclaimedReward = 
                    stakersRecord[msg.sender][index].availableUnclaimedReward - _amount;
                _amount = 0;
            } else {
                _amount = _amount - stakersRecord[msg.sender][index].availableUnclaimedReward;
                stakersRecord[msg.sender][index].availableUnclaimedReward = 0;
                stakersRecord[msg.sender][index].withdrawn = true;
            }
        }

        rewardToken.transfer(msg.sender, sendReward);
        
        totalClaimedRewardToken = totalClaimedRewardToken.add(sendReward);
        Stakers[msg.sender].totalClaimedRewardTokenUser = Stakers[msg.sender]
            .totalClaimedRewardTokenUser
            .add(sendReward);
    }

    function getMaxUnstakeAmount( address user ) public view returns ( uint256 ) {
        uint256 maxUnstakeAmount;
        for ( uint256 index ; index < Stakers[user].stakeCount ; index++ ) {
            if ( !stakersRecord[user][index].unstaked ) {
                if ( stakersRecord[user][index].unstakeTime < block.timestamp ) {
                    maxUnstakeAmount = maxUnstakeAmount
                        .add( stakersRecord[user][index].availableUnstakedAmount );
                }
            }
        }
        return maxUnstakeAmount;
    }

    function getMaxUncliamedAmount( address user ) public view returns ( uint256 ) {
        uint256 maxUnClaimedAmount;
        for( uint256 index ; index < Stakers[user].stakeCount ; index++ ) {
            if ( !stakersRecord[user][index].withdrawn ) {
                if( stakersRecord[user][index].unstakeTime < block.timestamp ) {
                    maxUnClaimedAmount = maxUnClaimedAmount
                        .add( stakersRecord[user][index].availableUnclaimedReward );
                }
            }
        }
        return maxUnClaimedAmount;
    }

    function getIndexStaker( uint256 _index ) public view returns ( address ) {
        return StakersID[_index];
    }

    function getIndexStakerUnstakedToken( address _index ) public view returns ( uint256 ) {
        return Stakers[_index].totalUnstakedTokenUser;
    }

    function getIndexStakerStakeCount( address _index ) public view returns ( uint256 ) {
        return Stakers[_index].stakeCount;
    }

    function setStakeLimits( uint256 _min, uint256 _max ) external onlyOwner {
        minStakeableToken = _min;
        maxStakeableToken = _max;
    }

    function setStakeDuration( uint256 _duration ) external onlyOwner {
        duration = _duration;
    }
}