// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
interface IOldChipRaceContract {
     function getInfo(uint256 _tokenId) external view returns(uint256 level, uint256 remainningTime, uint256 score, uint256 rewards, bool canUpgrade, bool isEnter);
}
contract ChipRaceContract is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    ERC721Enumerable g_firstNftAddress;
    ERC721Enumerable g_secondNftAddress;
    IERC20 g_craceToken;
    IOldChipRaceContract g_oldContract;

    struct TokenInfo {
        address owner;
        uint256 level;
        uint256 rewards;
        uint256 score;
        uint256 timeStamp;
        uint256 runningCounter;
        bool isRunning;
        bool isRestored;
    }
    //Variable for score per level
    mapping(uint256 => uint256) public g_targetScores;
    //Variable for save info per nft token
    mapping(uint256 => TokenInfo) public g_tokenInfo;
    //Variable for car type
    mapping(string => uint256) public g_carType;
    //Variable for reward system
    mapping(uint256 => mapping(uint256 => uint256)) public g_minableAmount;
    //Variable for upgrade NFT
    mapping(uint256 => mapping(uint256 => uint256)) public g_amountForUpgrade;

    mapping(uint256 => uint256) public g_poolRewardsAmount;

    uint256 public g_maxLockTime;
    uint256 public feeAmount;
    uint256 public feePrice;
    uint256 public g_eventDoubling;
    address public g_caller;
    address private g_expUpdater;

    event EnterChipRace(uint256 _tokenId, uint256 _poolId);
    event EmergencyExitChipRace(uint256 _tokenId, uint256 _feeAmount);
    event ClaimRewardsFromChipRace(uint256 _tokenId, uint256 _passedMins);
    event UpgradeNFT(uint256 _tokenId, uint256 _feeAmount);
    event UpdateScore(uint256[] _tokenIds);

    constructor(ERC721Enumerable g_firstAddress,ERC721Enumerable _secondAddress, IERC20 _tokenAddress, address _oldChip ) {
        g_firstNftAddress = g_firstAddress;
        g_secondNftAddress = _secondAddress;
        g_craceToken = _tokenAddress;
        g_oldContract = IOldChipRaceContract(_oldChip);
        g_maxLockTime = 60 * 24 * 7;
        feeAmount = 0;
        feePrice = 10 * 10 ** 18;
        g_eventDoubling = 1;
    }
    function restoreInfo(uint256 _tokenId) internal {
        TokenInfo storage info = g_tokenInfo[_tokenId];
        uint256 level;
        uint256 remainningTime;
        uint256 score;
        uint256 rewards;
        bool canUpgrade;
        bool isEnter;
        (level, remainningTime, score, rewards, canUpgrade, isEnter) = g_oldContract.getInfo(_tokenId);
        info.level = level;
        info.score = score;
        info.rewards = rewards;
        info.isRunning = isEnter;
        info.isRestored = true;
    }
    //------------------------External Functions--------------------------------------
    function getLevelOf(uint256 _tokenId) external view returns(uint256) {
        return g_tokenInfo[_tokenId].level;
    }
    function isRunningChipRace(uint256 _tokenId) external view returns(bool) {
        return g_tokenInfo[_tokenId].isRunning;
    }
    function isUpgradable(uint256 _tokenId) external view returns (bool) {
        uint256 level = g_tokenInfo[_tokenId].level;
        if ((g_targetScores[level + 1] != 0) &&(g_tokenInfo[_tokenId].score >= g_targetScores[level + 1]))
            return true;
        return false;
    }
    function getCarTypeOf(string memory _tokenURI) external view returns(uint256) {
        return g_carType[_tokenURI];
    }
    function getRemainingTime(uint256 _tokenId) external view returns(uint256) {
        return block.timestamp - g_tokenInfo[_tokenId].timeStamp;
    }
    function getOwnerOf(uint256 _tokenId) external view returns(address) {
        if(_tokenId > 5000)
            return g_secondNftAddress.ownerOf(_tokenId);
       
        return g_firstNftAddress.ownerOf(_tokenId);
    }
    function getInfo(uint256 _tokenId) external view returns(uint256 level, uint256 remainningTime, uint256 score, uint256 rewards, bool canUpgrade, bool isEnter) {
        if(g_tokenInfo[_tokenId].isRestored == false)
            return g_oldContract.getInfo(_tokenId);

        uint256 remainTime = block.timestamp - g_tokenInfo[_tokenId].timeStamp;
        uint256 tokenLevel = g_tokenInfo[_tokenId].level;
        bool flag = false;
        uint256 id = _tokenId;
        if ((g_targetScores[tokenLevel + 1] != 0) &&(g_tokenInfo[_tokenId].score >= g_targetScores[tokenLevel + 1]))
            flag = true;
        return(g_tokenInfo[id].level, remainTime, g_tokenInfo[id].score, g_tokenInfo[id].rewards, flag, g_tokenInfo[id].isRunning);
    }
    function enterChipRace(uint256 _tokenId, uint256 _poolId) external {
        if(g_tokenInfo[_tokenId].isRestored == false)
            restoreInfo(_tokenId);

        ERC721Enumerable g_nftFactoryAddress;
        if(_tokenId > 5000)
            g_nftFactoryAddress = g_secondNftAddress;
        else
            g_nftFactoryAddress = g_firstNftAddress;

        require(this.getOwnerOf(_tokenId) == msg.sender, "You are not a owner of this NFT");
        require(g_tokenInfo[_tokenId].isRunning == false, "You are already running with this NFT");
        require(g_carType[g_nftFactoryAddress.tokenURI(_tokenId)] == _poolId, "You can't enter this pool with this NFT");
        require(g_nftFactoryAddress.getApproved(_tokenId) == address(this), "Require NFT ownership transfer approval");

        g_nftFactoryAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        TokenInfo storage info = g_tokenInfo[_tokenId];
        info.owner = msg.sender;
        info.isRunning = true;
        info.runningCounter = info.runningCounter + 1;
        info.timeStamp = block.timestamp;
        emit EnterChipRace(_tokenId, _poolId);
    }
    function claimRewards(uint256 _tokenId) external {
        ERC721Enumerable g_nftFactoryAddress;
        if(_tokenId > 5000)
            g_nftFactoryAddress = g_secondNftAddress;
        else
            g_nftFactoryAddress = g_firstNftAddress;

        require(g_tokenInfo[_tokenId].owner == msg.sender, "You are not a owner of this NFT");
        require(g_tokenInfo[_tokenId].isRunning == true, "You didn't run the race!");

        
        uint256 passedMins = (block.timestamp - g_tokenInfo[_tokenId].timeStamp) / 60;
        uint256 carType = g_carType[g_nftFactoryAddress.tokenURI(_tokenId)];
        TokenInfo storage info = g_tokenInfo[_tokenId];
        uint256 amount = 0;
        uint256 times = 0;
        if(passedMins >= g_maxLockTime)
            times = g_maxLockTime;
            
        else
            times = passedMins;

        amount = g_minableAmount[carType][info.level] * times * g_eventDoubling;
        require(g_poolRewardsAmount[carType] >= amount, "No enough rewards amount in that pool");

        g_craceToken.safeTransfer(msg.sender, amount);
        g_nftFactoryAddress.safeTransferFrom(address(this), msg.sender, _tokenId);
        info.rewards = info.rewards + amount;
        info.isRunning = false;
        g_poolRewardsAmount[carType] = g_poolRewardsAmount[carType] - amount;
        emit ClaimRewardsFromChipRace(_tokenId, times);
    }

    function upgradeNFT(uint256 _tokenId, uint256 _amount) external {
        if(g_tokenInfo[_tokenId].isRestored == false)
            restoreInfo(_tokenId);

        ERC721Enumerable g_nftFactoryAddress;
        if(_tokenId > 5000)
            g_nftFactoryAddress = g_secondNftAddress;
        else
            g_nftFactoryAddress = g_firstNftAddress;

        require(this.getOwnerOf(_tokenId) == msg.sender, "You are not a owner of this NFT" );
        require(this.isUpgradable(_tokenId) == true, "You can't upgrade NFT because didn't reach target score");
        require(g_tokenInfo[_tokenId].isRunning == false, "You can't upgrade NFT during racing");
        uint256 carType = g_carType[g_nftFactoryAddress.tokenURI(_tokenId)];
        TokenInfo storage info = g_tokenInfo[_tokenId];
        require(g_amountForUpgrade[carType][info.level + 1] != 0, "You can't upgrade NFT anymore");
        require(g_amountForUpgrade[carType][info.level + 1] == _amount, "You didn't send enough amount for Upgrade");
        g_craceToken.safeTransferFrom(msg.sender, address(this), _amount);
        info.level = info.level + 1;
        emit UpgradeNFT(_tokenId, _amount);
    }
    
    function updateScore(uint256 _score, uint256[] memory tokenIds) external {
        require(msg.sender == g_caller, "This function is called by only PvP contract");
        
        for(uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(g_tokenInfo[tokenId].isRestored == false)
                restoreInfo(tokenId);
            TokenInfo storage info = g_tokenInfo[tokenId];
            info.score = info.score + _score;
        }
        emit UpdateScore(tokenIds);
    }
    function updateExp(uint256 _tokenId, uint256 _exp) external {
        require(msg.sender == g_expUpdater, "You can't update score by yourself!");
        TokenInfo storage info = g_tokenInfo[_tokenId];
        info.score = info.score + _exp;
    }
    //------------------------Internal Functions--------------------------------------


    //------------------------Owner Functions--------------------------------------
    function setEventDoubling(uint256 _doubling) external onlyOwner {
        g_eventDoubling = _doubling;
    }
    function setCaller(address _caller) external onlyOwner {
        g_caller = _caller;
    }
    function setExpUpdater(address _caller) external onlyOwner {
        g_expUpdater = _caller;
    }
    function setTargetScoreOf(uint256 _level, uint256 _targetScore) external onlyOwner {
        g_targetScores[_level] = _targetScore;
    }
    function setCarType(string memory _uri, uint256 _type) external onlyOwner {
        g_carType[_uri] = _type;
    }
    function setMinableAmount(uint256 _type, uint256 _level, uint256 _amount) external onlyOwner {
        g_minableAmount[_type][_level] = _amount ;
    }
    function setUpgradeAmount(uint256 _type, uint256 _level, uint256 _amount) external onlyOwner {
        g_amountForUpgrade[_type][_level] = _amount;
    }
    function setFeePrice(uint256 _price) external onlyOwner {
        feePrice = _price;
    }
    function setMaxLockTime(uint256 _time) external onlyOwner {
        g_maxLockTime = _time;
    }
    function withdrawFeeAmount() external onlyOwner {
        require(feeAmount > 0, "No fee amount!");
        g_craceToken.transfer(msg.sender, feeAmount);
        feeAmount = 0;
    }
    function withdrawAllFunds() external onlyOwner {
        uint256 amount = g_craceToken.balanceOf(address(this));
        g_craceToken.transfer(msg.sender, amount);
    }
    function depositeFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "No funds");
        g_craceToken.transferFrom(msg.sender, address(this), _amount);
        for(uint i = 1; i < 6; i++)
            g_poolRewardsAmount[i] = _amount / 5;
    }
    function depositePoolFunds(uint256 _poolId, uint256 _amount) external onlyOwner {
        require(_amount > 0, "No funds");
        g_craceToken.transferFrom(msg.sender, address(this), _amount);
        g_poolRewardsAmount[_poolId] = g_poolRewardsAmount[_poolId] + _amount;
    }
    
    function withdrawPoolFunds(uint256 _poolId, uint256 _amount) external onlyOwner {
        require(_amount > 0, "No funds");
        require((_amount) < g_poolRewardsAmount[_poolId], "No enough funds");
        g_craceToken.transfer(msg.sender, _amount );
        g_poolRewardsAmount[_poolId] = g_poolRewardsAmount[_poolId] - _amount;
    }

    function withdrawNFT(uint256 _tokenId) external onlyOwner {
        ERC721Enumerable g_nftFactoryAddress;
        if(_tokenId > 5000)
            g_nftFactoryAddress = g_secondNftAddress;
        else
            g_nftFactoryAddress = g_firstNftAddress;
        address owner = g_tokenInfo[_tokenId].owner;
        require(owner != address(0), "This token isn't staked!");
        g_nftFactoryAddress.safeTransferFrom(address(this), owner, _tokenId);

        TokenInfo storage info = g_tokenInfo[_tokenId];
        info.isRunning = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}