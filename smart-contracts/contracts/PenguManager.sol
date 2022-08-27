// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./HederaResponseCodes.sol";
import "./IHederaTokenService.sol";
import "./HederaTokenService.sol";
import "./ExpiryHelper.sol";

contract PenguManaer is ExpiryHelper {

    struct RewardNFTInfo{
        int64 id;
        uint256 startTime;
        uint256 lastClaimTime;
        address owner;
    }

    address owner;
    address penguPalTokenAddress;
    address penguNFTTokenAddress;
    address penguNFTGoldTokenAddress;

    uint256 dailyReward = 100 * 10 ** 8 / (3600 * 24); //pengupal decimal is 8
    uint256 maxNFTPerUser = 100;
    mapping(address => RewardNFTInfo[]) rewardUserInfo;
    mapping(int64 => bool) stakedNFTInfo;
    
    mapping(address => RewardNFTInfo[]) rewardUserGoldInfo;
    mapping(int64 => bool) stakedNFTGoldInfo;

    constructor(address _penguPalTokenAddress, address _penguNFTTokenAddress, address _penguNFTGoldTokenAddress) {
        owner = msg.sender;
        penguPalTokenAddress = _penguPalTokenAddress;
        penguNFTTokenAddress = _penguNFTTokenAddress;
        penguNFTGoldTokenAddress = _penguNFTGoldTokenAddress;
    }

    //only owner
    function setDailyReward(uint256 newReward) external {
        require(owner == msg.sender, "Only Owner Can Call This Function!");
        dailyReward = newReward / ( 3600 * 24 );
    }

    function getDailyReward() external returns(uint256){
        return dailyReward;
    }

    //only owner
    function setPenguPalTokenAddress(address _penguPalTokenAddress) external {
        require(owner == msg.sender, "Only Owner Can Call This Function!");
        penguPalTokenAddress = _penguPalTokenAddress;
    }

    function getPenguPalTokenAddress() external returns(address){
        return penguPalTokenAddress;
    }

    //only owner
    function setPenguNFTTokenAddress(address _penguNFTTokenAddress) external {
        require(owner == msg.sender, "Only Owner Can Call This Function!");
        penguNFTTokenAddress = _penguNFTTokenAddress;
    }

    function getPenguNFTTokenAddress() external returns(address){
        return penguNFTTokenAddress;
    }

    //only owner
    function setPenguNFTGoldTokenAddress(address _penguNFTGoldTokenAddress) external {
        require(owner == msg.sender, "Only Owner Can Call This Function!");
        penguNFTGoldTokenAddress = _penguNFTGoldTokenAddress;
    }

    function getPenguNFTGoldTokenAddress() external returns(address){
        return penguNFTGoldTokenAddress;
    }
    
    function stakeNFT(int64 nftID) external{
        
        require(stakedNFTInfo[nftID] == false, "Already Staked!");

        //check msg.sender is the owner of this nft and transfer nft to this contract
        int response1 = HederaTokenService.associateToken(address(this), penguNFTTokenAddress);

        require(response1 == SUCCESS, "Failed to Associate NFT this contract");

        int response2 = HederaTokenService.transferNFT(penguNFTTokenAddress, msg.sender, address(this), nftID);

        require(response2 == SUCCESS, "Failed to Transfer NFT to this contract");

        RewardNFTInfo memory newStakedNFT;
        newStakedNFT.id = nftID;
        newStakedNFT.startTime = block.timestamp;
        newStakedNFT.lastClaimTime = block.timestamp;
        newStakedNFT.owner = msg.sender;

        rewardUserInfo[msg.sender].push(newStakedNFT);

        stakedNFTInfo[nftID] = true;
    }

    function unstakeNFT(int64 nftID) external{
        require(stakedNFTInfo[nftID] == true, "Not Staked!");

        uint256 idx;
        int response1;
        int response2;

        for( idx = 0; idx < rewardUserInfo[msg.sender].length; idx++ )
        {
            if( rewardUserInfo[msg.sender][idx].id != nftID || rewardUserInfo[msg.sender][idx].owner != msg.sender )
                continue;
            //give reward to user, 
            uint256 rewardAmount = (block.timestamp - rewardUserInfo[msg.sender][idx].lastClaimTime) * dailyReward;

            response1 = HederaTokenService.associateToken(address(this), penguPalTokenAddress);
            require(response1 == SUCCESS, "Failed to Associate Pengupal this contract");
    
            response2 = HederaTokenService.transferToken(penguPalTokenAddress, address(this), msg.sender, rewardAmount);    
            require(response2 == SUCCESS, "Failed to Transfer Pengupal to msg.sender");

            //transfer nft to user
            response1 = HederaTokenService.associateToken(address(this), penguNFTTokenAddress);
            require(response1 == SUCCESS, "Failed to Associate NFT this contract");
    
            response2 = HederaTokenService.transferNFT(penguNFTTokenAddress, address(this), msg.sender, rewardUserInfo[msg.sender][idx].id);    
            require(response2 == SUCCESS, "Failed to Transfer NFT to this contract");

            rewardUserInfo[msg.sender][idx] = rewardUserInfo[msg.sender][rewardUserInfo[msg.sender].length -1];
            rewardUserInfo[msg.sender].pop();

            stakedNFTInfo[nftID] = false;
        }
    }

    function stakeGoldNFT(int64 nftID) external{
        
        require(stakedNFTGoldInfo[nftID] == false, "Already Staked!");

        //check msg.sender is the owner of this nft and transfer nft to this contract
        int response1 = HederaTokenService.associateToken(address(this), penguNFTGoldTokenAddress);

        require(response1 == SUCCESS, "Failed to Associate NFT this contract");

        int response2 = HederaTokenService.transferNFT(penguNFTGoldTokenAddress, msg.sender, address(this), nftID);

        require(response2 == SUCCESS, "Failed to Transfer NFT to this contract");

        RewardNFTInfo memory newStakedNFT;
        newStakedNFT.id = nftID;
        newStakedNFT.startTime = block.timestamp;
        newStakedNFT.lastClaimTime = block.timestamp;
        newStakedNFT.owner = msg.sender;

        rewardUserGoldInfo[msg.sender].push(newStakedNFT);

        stakedNFTGoldInfo[nftID] = true;
    }

    function getStakedNFT() external returns(RewardNFTInfo[] memory)
    {
        return stakedNFTInfo[msg.sender];
    }

    function getStakedGoldNFT() external returns(RewardNFTInfo[] memory)
    {
        return stakedNFTGoldInfo[msg.sender];
    }

    function unstakeGoldNFT(int64 nftID) external{
        require(stakedNFTGoldInfo[nftID] == true, "Not Staked!");

        uint256 idx;
        int response1;
        int response2;

        for( idx = 0; idx < rewardUserGoldInfo[msg.sender].length; idx++ )
        {
            if( rewardUserGoldInfo[msg.sender][idx].id != nftID || rewardUserGoldInfo[msg.sender][idx].owner != msg.sender )
                continue;
            //give reward to user, 
            uint256 rewardAmount = (block.timestamp - rewardUserGoldInfo[msg.sender][idx].lastClaimTime) * dailyReward;

            response1 = HederaTokenService.associateToken(address(this), penguPalTokenAddress);
            require(response1 == SUCCESS, "Failed to Associate Pengupal this contract");
    
            response2 = HederaTokenService.transferToken(penguPalTokenAddress, address(this), msg.sender, rewardAmount);    
            require(response2 == SUCCESS, "Failed to Transfer Pengupal to msg.sender");

            //transfer nft to user
            response1 = HederaTokenService.associateToken(address(this), penguPalGoldTokenAddress);
            require(response1 == SUCCESS, "Failed to Associate NFT this contract");
    
            response2 = HederaTokenService.transferNFT(penguPalGoldTokenAddress, address(this), msg.sender, rewardUserGoldInfo[msg.sender][idx].id);    
            require(response2 == SUCCESS, "Failed to Transfer NFT to this contract");

            rewardUserGoldInfo[msg.sender][idx] = rewardUserGoldInfo[msg.sender][rewardUserGoldInfo[msg.sender].length -1];
            rewardUserGoldInfo[msg.sender].pop();

            stakedNFTGoldInfo[nftID] = false;
        }
    }

    function claim() external{

        uint256 idx;
        uint256 rewardSum = 0;
        uint256 goldenNFTCount = 0;

        for(idx = 0; idx < rewardUserInfo[msg.sender].length; idx++)
        {
            //check goldenNFTCount
            rewardSum += (block.timestamp - rewardUserInfo[msg.sender][idx].lastClaimTime) * dailyReward;
            rewardUserInfo[msg.sender][idx].lastClaimTime = block.timestamp;            
        }

        for(idx = 0; idx < rewardUserGoldInfo[msg.sender].length; idx++)
        {
            //check goldenNFTCount
            rewardSum += (block.timestamp - rewardUserGoldInfo[msg.sender][idx].lastClaimTime) * dailyReward;
            rewardUserGoldInfo[msg.sender][idx].lastClaimTime = block.timestamp;   
            goldenNFTCount++;         
        }

        if( goldenNFTCount > 0 )
        {
            rewardSum *= goldenNFTCount * 2;
        }

        require(rewardSum != 0, "No reward to this user!");

        //transfer reward to user
        response1 = HederaTokenService.associateToken(address(this), penguPalTokenAddress);
        require(response1 == SUCCESS, "Failed to Associate Pengupal this contract");

        response2 = HederaTokenService.transferToken(penguPalTokenAddress, address(this), msg.sender, rewardSum);    
        require(response2 == SUCCESS, "Failed to Transfer Pengupal to msg.sender");

    }
    
}
