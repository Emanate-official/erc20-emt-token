// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IMinter} from "./interfaces/IMinter.sol";
// import "hardhat/console.sol";

/// @title Rewards
/// @notice Rewards for participation in the moda ecosystem.
/// @dev Rewards for participation in the moda ecosystem.
contract Rewards is Ownable {
    /// @notice utility constant
    uint256 public constant DECIMALS = 10**18;
    uint256 public constant REWARD_PER_BLOCK = 29;

    using SafeMath for uint256;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event DepositAMMLPTokensEvent(
        address indexed user,
        address indexed lpAddress,
        uint256 amount
    );
    event WithdrawAMMLPTokensEvent(
        address indexed user,
        address indexed lpAddress,
        uint256 amount
    );
    event DepositMinterCollateralByAddress(
        address indexed user,
        address indexed collateralAddress,
        uint256 amount
    );
    event WithdrawMinterCollateralByAddress(
        address indexed user,
        address indexed collateralAddress,
        uint256 amount
    );
    event MinterRewardPoolRatioUpdatedEvent(
        address collateralAddress,
        uint256 accmodaPerShare,
        uint256 lastRewardBlock
    );
    event AmmLPRewardUpdatedEvent(
        address lpAddress,
        uint256 accmodaPerShare,
        uint256 lastRewardBlock
    );
    event VestedRewardsReleasedEvent(uint256 amount, uint256 timestamp);

    /****************************************
     *                VARIABLES              *
     ****************************************/

    struct UserInfo {
        uint256 amount; // How many collateral or LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct Pool {
        address poolAddress;
        uint256 allocPoint;
    }

    struct PoolInfo {
        bool whitelisted; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Used to calculate ratio of rewards for this amm pool out of total
        uint256 lastRewardBlock; // Last block number that moda distribution occured.
        uint256 accmodaPerShare; // Accumulated moda per share, times 10^18.
    }

    /// @notice address of the moda erc20 token
    address public immutable modaTokenAddress;
    /// @notice block number of rewards genesis
    uint256 public genesisBlock;
    /// @notice rewards allocated for the first month
    uint256 public immutable startingRewards;
    /// @notice length of a month = 30*24*60*60
    uint256 public immutable epochLength;
    /// @notice percentage of rewards allocated to minter Lps
    uint256 public minterLpRewardsRatio; //in bps, multiply fraction by 10^4
    /// @notice percentage of rewards allocated to minter Amm Lps
    uint256 public ammLpRewardsRatio; //in bps, multiply fraction by 10^4
    /// @notice percentage of rewards allocated to stakers
    uint256 public vestingRewardsRatio; //in bps, multiply fraction by 10^4
    /// @notice total alloc points for amm lps
    uint256 public totalAmmLpAllocs; //total allocation points for all amm lps (the ratio defines percentage of rewards to a particular amm lp)
    /// @notice total alloc points for minter lps
    uint256 public totalMinterLpAllocs; //total allocation points for all minter lps (the ratio defines percentage of rewards to a particular minter lp)

    /// @notice reward for stakers already paid
    uint256 public vestingRewardsDebt;

    /// @notice address of the minter contract
    address public minterContract;

    /// @notice address of the staking contract
    address public modaChestContract;

    /// @notice timestamp of last allocation of rewards to stakers
    uint256 public lastmodaVestRewardBlock;

    /// @notice info of whitelisted AMM Lp pools
    mapping(address => PoolInfo) public ammLpPools;
    /// @notice info of whitelisted minter Lp pools
    mapping(address => PoolInfo) public minterLpPools;
    /// @notice info of amm Lps
    mapping(address => mapping(address => UserInfo)) public ammLpUserInfo;
    /// @notice info of minter Lps
    mapping(address => mapping(address => UserInfo)) public minterLpUserInfo;

    mapping(address => uint256) public claimedmoda;

    /****************************************
     *          PRIVATE VARIABLES            *
     ****************************************/

    // @notice stores the AMM LP pool addresses internally
    address[] internal ammLpPoolsAddresses;

    /****************************************
     *           PUBLIC FUNCTIONS           *
     ****************************************/

    function monthlymoda() public view returns (uint256) {
        return startingRewards.mul(sumExp(1, nMonths())).div(DECIMALS);
    }

    function thisMonthsReward() public view returns (uint256) {
        return startingRewards.mul(exp(1, nMonths() + 1)).div(DECIMALS);
    }

    function accmoda(uint256 diffTime) public view returns (uint256) {
        require(diffTime > 0, "Invalid diff time");
        uint256 accMonthlymoda = monthlymoda();
        return (diffTime.mul(thisMonthsReward()).div(DECIMALS)).add(accMonthlymoda);
    }

    function unclaimed() public view returns (uint256) {
        return unclaimed(diffTime());
    }

    function unclaimed(uint256 diffTime) public view returns (uint256) {
        require(diffTime > 0, "Invalid diff time");
        uint256 _accmoda = accmoda(diffTime);
        return (_accmoda.mul(vestingRewardsRatio).div(BPS)).sub(vestingRewardsDebt);
    }

    function nMonths() public view returns (uint256) {
        return (now.sub(genesisBlock)).div(epochLength);
    }

    function diffTime() public view returns (uint256) {
        return (now.sub(genesisBlock.add(epochLength.mul(nMonths()))).mul(DECIMALS))
                .div(epochLength);
    }

    /// @notice initiates the contract with predefined params
    /// @dev initiates the contract with predefined params
    /// @param _modaTokenAddress address of the moda erc20 token
    /// @param _startingRewards rewards allocated for the first month
    /// @param _epochLength length of a month = 30*24*60*60
    /// @param _minterLpRewardsRatio percentage of rewards allocated to minter Lps in bps
    /// @param _ammLpRewardsRatio percentage of rewards allocated to minter Amm Lps in bps
    /// @param _vestingRewardsRatio percentage of rewards allocated to stakers in bps
    /// @param _minter address of the minter contract
    /// @param _genesisBlock timestamp of rewards genesis
    /// @param _minterLpPools info of whitelisted minter Lp pools at genesis
    /// @param _ammLpPools info of whitelisted amm Lp pools at genesis
    constructor(
        address _modaTokenAddress,
        uint256 _startingRewards,
        uint256 _epochLength,
        uint256 _minterLpRewardsRatio, //in bps, multiplied by 10^4
        uint256 _ammLpRewardsRatio, //in bps, multiplied by 10^4
        uint256 _vestingRewardsRatio, //in bps, multiplied by 10^4
        address _minter,
        uint256 _genesisBlock,
        Pool[] memory _minterLpPools,
        Pool[] memory _ammLpPools
    ) public {
        modaTokenAddress = _modaTokenAddress;
        startingRewards = _startingRewards;
        epochLength = _epochLength;
        minterLpRewardsRatio = _minterLpRewardsRatio;
        ammLpRewardsRatio = _ammLpRewardsRatio;
        vestingRewardsRatio = _vestingRewardsRatio;
        minterContract = _minter;
        genesisBlock = _genesisBlock;
        lastmodaVestRewardBlock = genesisBlock;
        for (uint8 i = 0; i < _minterLpPools.length; i++) {
            addMinterCollateralType(
                _minterLpPools[i].poolAddress,
                _minterLpPools[i].allocPoint
            );
        }
        for (uint8 i = 0; i < _ammLpPools.length; i++) {
            addAmmLp(_ammLpPools[i].poolAddress, _ammLpPools[i].allocPoint);
        }
    }

    ///
    /// Updates accmodaPerShare and last reward update timestamp.
    /// Calculation:
    /// For each second, the total amount of rewards is fixed among all the current users who have staked LP tokens in the contract
    /// So, your share of the per second reward is proportionate to the amount of LP tokens you have staked in the pool.
    /// Hence, reward per second per collateral unit = reward per second / total collateral
    /// Since the total collateral remains the same between period when someone deposits or withdraws collateral,
    /// the per second reward per collateral unit also remains the same.
    /// So we just keep adding reward per share and keep a rewardDebt variable for each user to keep track of how much
    /// out of the accumulated reward they have already been paid or are not owed because of when they entered.
    ///
    ///
    /// @notice updates amm reward pool state
    /// @dev keeps track of accmodaPerShare as the number of stakers change
    /// @param _lpAddress address of the amm lp token
    function updateAmmRewardPool(address _lpAddress) public {
        PoolInfo storage pool = ammLpPools[_lpAddress];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(_lpAddress).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 totalRewards = calcReward(pool.lastRewardBlock);
        uint256 modaReward =
            totalRewards
                .mul(ammLpRewardsRatio)
                .mul(pool.allocPoint)
                .div(totalAmmLpAllocs)
                .div(BPS);

        pool.accmodaPerShare = pool.accmodaPerShare.add(
            modaReward.mul(DECIMALS).div(lpSupply)
        );

        pool.lastRewardBlock = block.number;

        emit AmmLPRewardUpdatedEvent(
            _lpAddress,
            pool.accmodaPerShare,
            pool.lastRewardBlock
        );
    }

    ///
    /// Updates accmodaPerShare and last reward update timestamp.
    /// Calculation:
    /// For each second, the amount of rewards is fixed among all the current users who have staked collateral in the contract
    /// So, your share of the per second reward is proportionate to your collateral in the pool.
    /// Hence, reward per second per collateral unit = reward per second / total collateral
    /// Since the total collateral remains the same between period when someone deposits or withdraws collateral,
    /// the per second reward per collateral unit also remains the same.
    /// So we just keep adding reward per share and keep a rewardDebt variable for each user to keep track of how much
    /// out of the accumulated reward they have already been paid.
    ///
    ///
    /// @notice updates minter reward pool state
    /// @dev keeps track of accmodaPerShare as the number of stakers change
    /// @param _collateralAddress address of the minter lp token
    function updateMinterRewardPool(address _collateralAddress) public {
        PoolInfo storage pool = minterLpPools[_collateralAddress];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 minterCollateralSupply =
            IMinter(minterContract).getTotalCollateralByCollateralAddress(
                _collateralAddress
            );

        if (minterCollateralSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 totalRewards = calcReward(pool.lastRewardBlock);
        uint256 modaReward =
            totalRewards
                .mul(minterLpRewardsRatio) // 4000 (0*4 ** BPS)
                .mul(pool.allocPoint) // 10
                .div(totalMinterLpAllocs) // 
                .div(BPS);

        pool.accmodaPerShare = pool.accmodaPerShare.add(
            modaReward.mul(DECIMALS).div(minterCollateralSupply)
            //modaReward
        );

        pool.lastRewardBlock = block.number;

        emit MinterRewardPoolRatioUpdatedEvent(
            _collateralAddress,
            pool.accmodaPerShare,
            pool.lastRewardBlock
        );
    }

    ///
    /// Deposit LP tokens and update reward debt for user and automatically sends accumulated rewards to the user.
    /// Reward debt keeps track of how much rewards have already been paid to the user + how much
    /// reward they are not entitled to that was earned before they entered the pool.
    ///
    ///
    /// @notice deposit amm lp tokens to earn rewards
    /// @dev deposit amm lp tokens to earn rewards
    /// @param _lpAddress address of the amm lp token
    /// @param _amount amount of lp tokens
    function depositPoolTokens(address _lpAddress, uint256 _amount) public {
        require(
            ammLpPools[_lpAddress].whitelisted == true,
            "Error: AMM Pool Address not allowed"
        );

        PoolInfo storage pool = ammLpPools[_lpAddress];
        UserInfo storage user = ammLpUserInfo[_lpAddress][msg.sender];

        updateAmmRewardPool(_lpAddress);

        if (user.amount > 0) {
            withdrawUnclaimedRewards(user, pool, msg.sender);
        }

        IERC20(_lpAddress).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        addAmountUpdateRewardDebtForUserForPoolTokens(
            _lpAddress,
            msg.sender,
            _amount
        );

        emit DepositAMMLPTokensEvent(msg.sender, _lpAddress, _amount);
    }

    /// @notice withdraw amm lp tokens to earn rewards
    /// @dev withdraw amm lp tokens to earn rewards
    /// @param _lpAddress address of the amm lp token
    /// @param _amount amount of lp tokens
    function withdrawPoolTokens(address _lpAddress, uint256 _amount) public {
        //require(lpPools[_lpAddress].whitelisted == true, "Error: Amm Lp not allowed"); //#DISCUSS: Allow withdraw from later blacklisted lp

        PoolInfo storage pool = ammLpPools[_lpAddress];
        UserInfo storage user = ammLpUserInfo[_lpAddress][msg.sender];

        require(user.amount >= _amount, "Error: Not enough balance");

        updateAmmRewardPool(_lpAddress);
        withdrawUnclaimedRewards(user, pool, msg.sender);

        subtractAmountUpdateRewardDebtForUserForPoolTokens(
            _lpAddress,
            msg.sender,
            _amount
        );

        IERC20(_lpAddress).transfer(address(msg.sender), _amount);

        emit WithdrawAMMLPTokensEvent(msg.sender, _lpAddress, _amount);
    }

    /// @notice deposit collateral to minter to earn rewards, called by minter contract
    /// @dev deposit collateral to minter to earn rewards, called by minter contract
    /// @param _collateralAddress address of the minter collateral token
    /// @param _account address of the user
    /// @param _amount amount of collateral tokens
    function depositMinter(
        address _collateralAddress,
        address _account,
        uint256 _amount
    ) public onlyMinter {
        require(
            minterLpPools[_collateralAddress].whitelisted == true,
            "Error: Collateral type not allowed"
        );

        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];

        updateMinterRewardPool(_collateralAddress);

        if (user.amount > 0) {
            withdrawUnclaimedRewards(user, pool, _account);
        }

        addAmountUpdateRewardDebtAndForMinter(
            _collateralAddress,
            _account,
            _amount
        );

        emit DepositMinterCollateralByAddress(
            _account,
            _collateralAddress,
            _amount
        );
    }

    /// @notice withdraw collateral from minter, called by minter contract
    /// @dev withdraw collateral from minter, called by minter contract
    /// @param _collateralAddress address of the minter collateral token
    /// @param _account address of the user
    /// @param _amount amount of collateral tokens
    function withdrawMinter(
        address _collateralAddress,
        address _account,
        uint256 _amount
    ) public onlyMinter {
        //require(lpPools[_lpAddress].whitelisted == true, "Error: Amm Lp not allowed"); //#DISCUSS: Allow withdraw from later blacklisted lps

        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];

        require(user.amount >= _amount, "Error: Not enough balance");

        updateMinterRewardPool(_collateralAddress);
        withdrawUnclaimedRewards(user, pool, _account);

        subtractAmountUpdateRewardDebtAndForMinter(
            _collateralAddress,
            _account,
            _amount
        );

        emit WithdrawMinterCollateralByAddress(
            _account,
            _collateralAddress,
            _amount
        );
    }

    /// @notice withdraw unclaimed amm lp rewards
    /// @dev withdraw unclaimed amm lp rewards, checks unclaimed rewards, updates rewardDebt
    /// @param _lpAddress address of the amm lp token
    function withdrawUnclaimedPoolRewards(address _lpAddress) external {
        PoolInfo storage pool = ammLpPools[_lpAddress];
        UserInfo storage user = ammLpUserInfo[_lpAddress][msg.sender];

        updateAmmRewardPool(_lpAddress);
        withdrawUnclaimedRewards(user, pool, msg.sender);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice withdraw unclaimed minter lp rewards
    /// @dev withdraw unclaimed minter lp rewards, checks unclaimed rewards, updates rewardDebt
    /// @param _collateralAddress address of the collateral token
    /// @param _account address of the user
    function withdrawUnclaimedMinterLpRewards(
        address _collateralAddress,
        address _account
    ) public onlyMinter {
        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];

        updateMinterRewardPool(_collateralAddress);
        withdrawUnclaimedRewards(user, pool, _account);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice total pool  alloc points
    /// @dev total pool alloc points
    /// @return total pool alloc points
    function getTotalPoolAllocationPoints() public view returns (uint256) {
        return totalAmmLpAllocs;
    }

    /// @notice total minter lp alloc points
    /// @dev total minter lp alloc points
    /// @return total minter lp alloc points
    function getTotalMinterLpAllocationPoints() public view returns (uint256) {
        return totalMinterLpAllocs;
    }

    /// @notice unclaimed pool rewards
    /// @dev view function to check unclaimed pool rewards for an account
    /// @param _lpAddress address of the pool token
    /// @param _account address of the user
    /// @return unclaimed pool rewards for the user
    function getUnclaimedPoolRewardsByUserByPool(
        address _lpAddress,
        address _account
    ) public view returns (uint256) {
        PoolInfo storage pool = ammLpPools[_lpAddress];
        UserInfo storage user = ammLpUserInfo[_lpAddress][_account];
        return
            (user.amount.mul(pool.accmodaPerShare).div(DECIMALS)).sub(
                user.rewardDebt
            );
    }

    /// @notice lp tokens deposited by user
    /// @dev view function to check the amount of lp tokens deposited by user
    /// @param _lpAddress address of the amm lp token
    /// @param _account address of the user
    /// @return lp tokens deposited by user
    function getDepositedPoolTokenBalanceByUser(
        address _lpAddress,
        address _account
    ) public view returns (uint256) {
        UserInfo storage user = ammLpUserInfo[_lpAddress][_account];
        return user.amount;
    }

    /// @notice unclaimed minter lp rewards
    /// @dev view function to check unclaimed minter lp rewards for an account
    /// @param _collateralAddress address of the collateral token
    /// @param _account address of the user
    /// @return unclaimed minter lp rewards for the user
    function getUnclaimedMinterLpRewardsByUser(
        address _collateralAddress,
        address _account
    ) public view returns (uint256) {
        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];
        return
            (user.amount.mul(pool.accmodaPerShare).div(DECIMALS)).sub(
                user.rewardDebt
            );
    }

    /// @notice unclaimed rewards for stakers
    /// @dev view function to check unclaimed rewards for stakers since last withdrawal to vesting contract
    /// @return unclaimed rewards for stakers
    function getUnclaimedVestingRewards() public view returns (uint256) {
        uint256 _unclaimed = unclaimed(diffTime());
        return _unclaimed;
    }

    /// @notice checks if an amm lp address is whitelisted
    /// @dev checks if an amm lp address is whitelisted
    /// @param _lpAddress address of the lp token
    /// @return true if valid amm lp
    function isValidAmmLp(address _lpAddress) public view returns (bool) {
        return ammLpPools[_lpAddress].whitelisted;
    }

    /// @notice checks if a collateral address is whitelisted
    /// @dev checks if a collateral address is whitelisted
    /// @param _collateralAddress address of the collateral
    /// @return true if valid minter lp
    function isValidMinterLp(address _collateralAddress)
        public
        view
        returns (bool)
    {
        return minterLpPools[_collateralAddress].whitelisted;
    }

    /// @notice view amm lp pool info
    /// @dev view amm lp pool info
    /// @param _lpAddress address of the lp token
    /// @return poolinfo
    function getAmmLpPoolInfo(address _lpAddress)
        public
        view
        returns (PoolInfo memory)
    {
        return ammLpPools[_lpAddress];
    }

    /// @notice view minter lp pool info
    /// @dev view minter lp pool info
    /// @param _collateralAddress address of the collateral
    /// @return view minter lp pool info
    function getMinterLpPoolInfo(address _collateralAddress)
        public
        view
        returns (PoolInfo memory)
    {
        return minterLpPools[_collateralAddress];
    }

    /// @notice get total claimed moda by user
    /// @dev get total claimed moda by user
    /// @param _account address of the user
    /// @return total claimed moda by user
    function getTotalRewardsClaimedByUser(address _account)
        public
        view
        returns (uint256)
    {
        return claimedmoda[_account];
    }

    /// @notice get all whitelisted AMM LM pool addresses
    /// @dev get all whitelisted AMM LM pool addresses
    /// @return AMM LP addresses as array
    function getWhitelistedAMMPoolAddresses()
        public
        view
        returns (address[] memory)
    {
        return ammLpPoolsAddresses;
    }

    /****************************************
     *            ADMIN FUNCTIONS            *
     ****************************************/

    /// @notice set alloc points for amm lp
    /// @dev set alloc points for amm lp
    /// @param _lpAddress address of the lp token
    /// @param _allocPoint alloc points
    function setAmmLpAllocationPoints(address _lpAddress, uint256 _allocPoint)
        public
        onlyOwner
    {
        require(
            ammLpPools[_lpAddress].whitelisted == true,
            "AMM LP Pool not whitelisted"
        );
        totalAmmLpAllocs = totalAmmLpAllocs
            .sub(ammLpPools[_lpAddress].allocPoint)
            .add(_allocPoint);
        ammLpPools[_lpAddress].allocPoint = _allocPoint;
    }

    /// @notice set alloc points for minter lp
    /// @dev set alloc points for minter lp
    /// @param _collateralAddress address of the collateral
    /// @param _allocPoint alloc points
    function setMinterLpAllocationPoints(
        address _collateralAddress,
        uint256 _allocPoint
    ) public onlyOwner {
        require(
            minterLpPools[_collateralAddress].whitelisted == true,
            "Collateral type not whitelisted"
        );
        totalMinterLpAllocs = totalMinterLpAllocs
            .sub(minterLpPools[_collateralAddress].allocPoint)
            .add(_allocPoint);
        minterLpPools[_collateralAddress].allocPoint = _allocPoint;
    }

    /// @notice add an amm lp pool
    /// @dev add an amm lp pool
    /// @param _lpAddress address of the amm lp token
    /// @param _allocPoint alloc points
    function addAmmLp(address _lpAddress, uint256 _allocPoint)
        public
        onlyOwner
    {
        require(
            ammLpPools[_lpAddress].whitelisted == false,
            "AMM LP Pool already added"
        );
        uint256 lastRewardBlock = block.number > genesisBlock ? block.number : genesisBlock;
        totalAmmLpAllocs = totalAmmLpAllocs.add(_allocPoint);

        //add lp to ammLpPools
        ammLpPools[_lpAddress].whitelisted = true;
        ammLpPools[_lpAddress].allocPoint = _allocPoint;
        ammLpPools[_lpAddress].lastRewardBlock = lastRewardBlock;
        ammLpPools[_lpAddress].accmodaPerShare = 0;

        // track the lp pool addresses addition internally
        addToAmmLpPoolsAddresses(_lpAddress);
    }

    /// @notice add a minter lp pool
    /// @dev add a minter lp pool
    /// @param _collateralAddress address of the collateral
    /// @param _allocPoint alloc points
    function addMinterCollateralType(
        address _collateralAddress,
        uint256 _allocPoint
    ) public onlyOwner {
        require(
            minterLpPools[_collateralAddress].whitelisted == false,
            "Collateral type already added"
        );
        uint256 lastRewardBlock = block.number > genesisBlock ? block.number : genesisBlock;
        totalMinterLpAllocs = totalMinterLpAllocs.add(_allocPoint);

        //add lp to ammLpPools
        minterLpPools[_collateralAddress].whitelisted = true;
        minterLpPools[_collateralAddress].allocPoint = _allocPoint;
        minterLpPools[_collateralAddress].lastRewardBlock = lastRewardBlock;
        minterLpPools[_collateralAddress].accmodaPerShare = 0;
    }

    /// @notice remove an amm lp pool
    /// @dev remove an amm lp pool
    /// @param _lpAddress address of the amm lp token
    function removeAmmLp(address _lpAddress) public onlyOwner {
        require(
            ammLpPools[_lpAddress].whitelisted == true,
            "AMM LP Pool not whitelisted"
        );
        totalAmmLpAllocs = totalAmmLpAllocs.sub(
            ammLpPools[_lpAddress].allocPoint
        );
        ammLpPools[_lpAddress].whitelisted = false;

        // track the lp pool addresses removal internally
        removeFromAmmLpPoolsAddresses(_lpAddress);
    }

    /// @notice remove a minter lp pool
    /// @dev remove a minter lp pool
    /// @param _collateralAddress address of the collateral
    function removeMinterCollateralType(address _collateralAddress)
        public
        onlyOwner
    {
        require(
            minterLpPools[_collateralAddress].whitelisted == true,
            "Collateral type not whitelisted"
        );
        updateMinterRewardPool(_collateralAddress);
        totalMinterLpAllocs = totalMinterLpAllocs.sub(
            minterLpPools[_collateralAddress].allocPoint
        );
        minterLpPools[_collateralAddress].whitelisted = false;
    }

    /// @notice releases unclaimed vested rewards for stakers for extra bonus
    /// @dev releases unclaimed vested rewards for stakers for extra bonus
    function releaseVestedRewards() public onlyOwner {
        require(block.number > lastmodaVestRewardBlock, "block.number<lastmodaVestRewardBlock");
        uint256 _diffTime = diffTime();

        require(
            _diffTime < epochLength.mul(DECIMALS),
            "_diffTime > epochLength.mul(DECIMALS)"
        );

        uint256 _accmoda = accmoda(_diffTime);
        uint256 _unclaimed = unclaimed(_diffTime);
            
        vestingRewardsDebt = _accmoda.mul(vestingRewardsRatio).div(BPS);
        safemodaTransfer(modaChestContract, _unclaimed);
        emit VestedRewardsReleasedEvent(_unclaimed, block.number);
    }

    /// @notice sets the address of the minter contract
    /// @dev set the address of the minter contract
    /// @param _minter address of the minter contract
    function setMinter(address _minter) public onlyOwner {
        minterContract = _minter;
    }

    /// @notice sets the address of the modachest contract
    /// @dev set the address of the modachest contract
    /// @param _modaChest address of the modachest contract
    function setmodaChest(address _modaChest) public onlyOwner {
        require(_modaChest != address(0), "Set to valid address");
        modaChestContract = _modaChest;
    }

    /// @notice set genesis timestamp
    /// @dev set genesis timestamp
    /// @param _genesisBlock genesis timestamp
    function setGenesisBlock(uint256 _genesisBlock) public onlyOwner {
        require(block.number < genesisBlock, "Already initialized");
        genesisBlock = _genesisBlock;
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @dev only minter contract can call function
    modifier onlyMinter() {
        require(
            msg.sender == minterContract,
            "Only minter contract can call this function"
        );
        _;
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    /// @notice Adds to LP token balance of user + updates reward debt of user
    /// @dev tracks either LP token amount or collateral ERC20 amount deposited by user + reward debt of user
    /// @param _poolAddress contract address of pool
    /// @param _account address of the user
    /// @param _amount LP token or collateral ERC20 balance
    function addAmountUpdateRewardDebtForUserForPoolTokens(
        address _poolAddress,
        address _account,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = ammLpPools[_poolAddress];
        UserInfo storage user = ammLpUserInfo[_poolAddress][_account];

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice Subtracts from LP token balance of user + updates reward debt of user
    /// @dev tracks either LP token amount or collateral ERC20 amount deposited by user + reward debt of user
    /// @param _poolAddress contract address of pool
    /// @param _account address of the user
    /// @param _amount LP token or collateral ERC20 balance
    function subtractAmountUpdateRewardDebtForUserForPoolTokens(
        address _poolAddress,
        address _account,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = ammLpPools[_poolAddress];
        UserInfo storage user = ammLpUserInfo[_poolAddress][_account];

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice Adds to collateral ERC20 balance of user + updates reward debt of user
    /// @dev tracks either LP token amount or collateral ERC20 amount deposited by user + reward debt of user
    /// @param _collateralAddress contract address of pool
    /// @param _account address of the user
    /// @param _amount LP token or collateral ERC20 balance
    function addAmountUpdateRewardDebtAndForMinter(
        address _collateralAddress,
        address _account,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice Subtracts from collateral ERC20 balance of user + updates reward debt of user
    /// @dev tracks either LP token amount or collateral ERC20 amount deposited by user + reward debt of user
    /// @param _collateralAddress contract address of pool
    /// @param _account address of the user
    /// @param _amount LP token or collateral ERC20 balance
    function subtractAmountUpdateRewardDebtAndForMinter(
        address _collateralAddress,
        address _account,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = minterLpPools[_collateralAddress];
        UserInfo storage user = minterLpUserInfo[_collateralAddress][_account];

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accmodaPerShare).div(DECIMALS);
    }

    /// @notice withdraw unclaimed rewards
    /// @dev withdraw unclaimed rewards
    /// @param user instance of the UserInfo struct
    /// @param pool instance of the PoolInfo struct
    /// @param account user address
    function withdrawUnclaimedRewards(
        UserInfo storage user,
        PoolInfo storage pool,
        address account
    ) internal {
        uint256 _unclaimed =
            user.amount.mul(pool.accmodaPerShare).div(DECIMALS).sub(
                user.rewardDebt
            );
        safemodaTransfer(account, _unclaimed);
    }

    /// @notice transfer moda to users
    /// @dev transfer moda to users
    /// @param _to address of the recipient
    /// @param _amount amount of moda tokens
    function safemodaTransfer(address _to, uint256 _amount) internal {
        uint256 modaBal = IERC20(modaTokenAddress).balanceOf(address(this));
        require(_amount <= modaBal, "Not enough moda tokens in the contract");
        IERC20(modaTokenAddress).transfer(_to, _amount);
        claimedmoda[_to] = claimedmoda[_to].add(_amount);
    }

    /// @notice calculates the unclaimed rewards for last timestamp
    /// @dev calculates the unclaimed rewards for last timestamp
    /// @param _from last timestamp when rewards were updated
    /// @return unclaimed rewards since last update
    function calcReward(uint256 _from) public view returns (uint256) {
        uint256 delta = block.number.sub(_from);
        return delta.mul(REWARD_PER_BLOCK).mul(BPS);
    }

    function exp(uint256 m, uint256 n) internal pure returns (uint256) {
        uint256 x = DECIMALS;
        for (uint256 i = 0; i < n; i++) {
            x = x.mul(m).div(DECIMALS);
        }
        return x;
    }

    function sumExp(uint256 m, uint256 n) internal pure returns (uint256) {
        uint256 x = DECIMALS;
        uint256 s;
        for (uint256 i = 0; i < n; i++) {
            x = x.mul(m).div(DECIMALS);
            s = s.add(x);
        }
        return s;
    }

    function addToAmmLpPoolsAddresses(address _lpAddress) internal {
        bool exists = false;
        for (uint8 i = 0; i < ammLpPoolsAddresses.length; i++) {
            if (ammLpPoolsAddresses[i] == _lpAddress) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            ammLpPoolsAddresses.push(_lpAddress);
        }
    }

    function removeFromAmmLpPoolsAddresses(address _lpAddress) internal {
        for (uint8 i = 0; i < ammLpPoolsAddresses.length; i++) {
            if (ammLpPoolsAddresses[i] == _lpAddress) {
                if (i + 1 < ammLpPoolsAddresses.length) {
                    ammLpPoolsAddresses[i] = ammLpPoolsAddresses[
                        ammLpPoolsAddresses.length - 1
                    ];
                }
                ammLpPoolsAddresses.pop();
                break;
            }
        }
    }
}
