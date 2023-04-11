// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utinols/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingContract {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;

    // using Counters for Counters.Counter;

    // Counters.Counter private _stakersCount;

    uint256 public _stakersCount = 0;

    // Track staked amounts for each user
    mapping(address => uint256) public stakes;
    
    //Array of staker addresses(0-uint256)
    mapping(uint256 => address) public stakers;

    mapping(address => uint256) public rewardsPerStaker;

    // Admin address to receive 50% of fees collected
    address public adminAddress;

    // Keep track of total staked amount and fees collected
    uint256 public totalStaked;
    uint256 public totalFeesCollected;
    uint256 emission;
    
    // 1000 * 100, 1000 to get percentage and 100 to get fraction
    uint256 constant PERCENTAGE_DIVISOR = 100000;  
     
    // Fee percentage taken from staked amount
    uint256 public feePercentage = 1000; // 1% fee

    // Event emitted when a user stakes their tokens
    event Staked(address indexed user, uint256 amount);

    // Event emitted when a user unstakes their tokens
    event Unstaked(address indexed user, uint256 amount);

    // Constructor function to set the admin address
    constructor(address _adminAddress, address _stakingToken) {
        adminAddress = _adminAddress;
        stakingToken = IERC20(_stakingToken);
    }

    // Function to stake tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Calculate fees and distribute to admin
        uint256 fees = (_amount * feePercentage) / PERCENTAGE_DIVISOR;
        uint256 adminFeeOrNetworkFee = fees / 2;
        uint256 totalAmountPayable = _amount + adminFeeOrNetworkFee;
        // Transfer tokens from user to contract
        // Assumes this contract has been approved to spend the tokens
        require(stakingToken.transferFrom(msg.sender, address(this), totalAmountPayable));
        //transfer fee directly tp the admin
        require(stakingToken.transferFrom(msg.sender, adminAddress, adminFeeOrNetworkFee));
        
        //If  new staker add it to stakers
        if(stakes[msg.sender] == 0){
            stakers[_stakersCount] = msg.sender;
            _stakersCount++;
        }
        
        totalFeesCollected += adminFeeOrNetworkFee;

        // Add staked amount to user's total and update total staked
        stakes[msg.sender] += _amount;
        totalStaked += _amount;

        // Emit staked event
        emit Staked(msg.sender, _amount);
    }

    // Function to unstake tokens
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Make sure user has enough staked tokens
        require(stakes[msg.sender] >= _amount, "Not enough staked tokens");

        // Calculate fees and distribute to admin
        uint256 fees = (_amount * feePercentage) / PERCENTAGE_DIVISOR;
        uint256 adminFeeOrNetworkFee = fees / 2;
        uint256 totalAmountWithdrawable = _amount - adminFeeOrNetworkFee;

        //Transfer 50 % of the fee to admin
        require(stakingToken.transfer(adminAddress, adminFeeOrNetworkFee));
        
        // Transfer staked tokens back to user
        require(stakingToken.transfer(msg.sender, totalAmountWithdrawable));
        
        //Add fees to totalfeescollecyted
        totalFeesCollected += adminFeeOrNetworkFee;

        // Subtract staked amount from user's total and update total staked
        stakes[msg.sender] -= _amount - fees;
        totalStaked -= _amount - fees;

        // Emit unstaked event
        emit Unstaked(msg.sender, _amount);
    }

    // Function to get the user's staked amount
    function getStakedAmount(address _user) external view returns (uint256) {
        return stakes[_user];
    }

    // Function to get the total staked amount
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    // Function to get the total fees collected
    function getTotalFeesCollected() external view returns (uint256) {
        return totalFeesCollected;
    }

    // Function to get the total Stakers Count
    function getTotalStakers() external view returns (uint256) {
        return _stakersCount;
    }

    function getCurrentPercentageStake(address _user) public view returns(uint256){
        uint256 userStakes= stakes[_user];
        uint256 percentage = ((userStakes* 1e18) /totalStaked );
        return (percentage);
    }

    function getRewardsStaker(address _user)public view returns(uint256){
        uint256 stakersPercentage =  getCurrentPercentageStake(_user);
        uint256 rewards = (stakersPercentage * totalFeesCollected) / 1e18;
        return(rewards);
    }

    // Function to distribute fees to all holders
    function distributeFees() external {
        // Make sure there are fees to distribute
        require(totalFeesCollected > 0, "No fees collected");

        for(uint256 i=0 ; i<_stakersCount; i++){
            uint256 userStakes= stakes[stakers[i]];
            uint256 percentage = ((userStakes* 1e18) /totalStaked );
            uint256 rewards = (percentage * totalFeesCollected) / 1e18;
            require(stakingToken.transfer(stakers[i], rewards));
            emission += rewards;
        }
    }
    
    // total fees distributed amongst the holders.
    function getEmission() external view returns (uint256) {
        
        return (emission);
    }
}