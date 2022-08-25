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

    uint256 dailyReward = 100 * 10 ** 8 / (3600 * 24); //pengupal decimal is 8
    uint256 maxNFTPerUser = 100;
    mapping(address => RewardNFTInfo[]) rewardUserInfo;
    mapping(int64 => bool) stakedNFTInfo;

    constructor(address _penguPalTokenAddress, address _penguNFTTokenAddress) {
        owner = msg.sender;
        penguPalTokenAddress = _penguPalTokenAddress;
        penguNFTTokenAddress = _penguNFTTokenAddress;
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

    function unStakeNFT(int64 nftID) external{
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
