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
    uint256 public totalUnStakedToken; // total amount of unstaked token
    uint256 public totalStakedToken; // total amount of staked token
    uint256 public totalClaimedRewardToken; // total amount of cliamed token
    uint256 public totalStakers; // total amount of stakers
    uint256 public percentDivider; // percent divider : proportion

    uint256 public duration = 20 seconds; // duration : lock time

    struct Stake {
        uint256 unstakeTime; // when unstake is available
        uint256 stakeTime; // when token is staked
        uint256 amount; // amount of staked token
        uint256 reward; // amount of reward(total)
        uint256 availableUnstakedAmount; // amount of unstake available token 
        uint256 availableUnclaimedReward; // amount of claim available reward
        bool withdrawn; // status: reward is taken
        bool unstaked; // status: stakeToken is unstaked
    }

    struct User {
        uint256 totalStakedTokenUser; // how much token did user stake
        uint256 totalUnstakedTokenUser; // how much token did user unstake
        uint256 totalClaimedRewardTokenUser; // how much reward did user claim
        uint256 stakeCount; // how many times did user stake
        bool alreadyExists; // is user already exists?
    }

    mapping(address => User) public Stakers; // stakers array
    mapping(uint256 => address) public StakersID; // staker ID array
    mapping(address => mapping(uint256 => Stake)) public stakersRecord; // record of stakers


    constructor( address _stakingToken, address _rewardingToken ) {
        stakeToken = ERC20(_stakingToken);
        rewardToken = ERC20(_rewardingToken);
        maxStakeableToken = stakeToken.totalSupply(); // set max stakeable token from stkeToken
        minStakeableToken = 1e13; // set minimum stakeable token
        percentDivider = 1e2;
    }

    function stake( uint256 _amount ) public {
        require(_amount >= minStakeableToken, "stake more than minimum amount");

        // insert msg.sender to stakers list
        if ( !Stakers[msg.sender].alreadyExists ) {
            Stakers[msg.sender].alreadyExists = true;
            StakersID[totalStakers] = msg.sender;
            totalStakers ++;
        }

        //transfer stakeToken to smart contract
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

    // unstake function
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

    // send reward to msg.sender
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

    // get availabe unstake token amount that user can unstake
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

    // get amount of reward that user can claim
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

    // get indexed staker
    function getIndexStaker( uint256 _index ) public view returns ( address ) {
        return StakersID[_index];
    }

    // get index staker's unstaked token
    function getIndexStakerUnstakedToken( address _index ) public view returns ( uint256 ) {
        return Stakers[_index].totalUnstakedTokenUser;
    }

    // get index stakers' stake count
    function getIndexStakerStakeCount( address _index ) public view returns ( uint256 ) {
        return Stakers[_index].stakeCount;
    }

    // set min, max stakeable token
    function setStakeLimits( uint256 _min, uint256 _max ) external onlyOwner {
        minStakeableToken = _min;
        maxStakeableToken = _max;
    }

    // set duration
    function setStakeDuration( uint256 _duration ) external onlyOwner {
        duration = _duration;
    }
}