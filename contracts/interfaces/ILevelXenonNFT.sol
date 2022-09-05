// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an XenonNFT compliant contract.
 */


interface IXenonNFT {

    event NFTrenamed(uint256 tokenId, string nftName);
    event URIUpdated(string[] URI);
    event NFTLeveledUp(uint256 tokenId);
    event UtilityUnlocked(uint256 tokenId, string utilitySlug);
    event NFTUtilityLevelUp(uint256 tokenId, string utilitySlug);
    event NFTBought(address buyer, uint256 price, uint256 tokenId);
    event WhiteListAddressAdded(address[] WL);
    event WhiteListAddressRemoved(address[] WL);

    /**
        @dev tells us the sale type isTOken or isETH
     */


    function getOwnerofNFT() external returns(address owner);

    /**
        returns factory
     */

    function getFactory() external returns(address factory);

    /**
        @dev returns sale end time
     */
    
    function getSaleEndTime() external returns(uint256 endTime);



    /**
        @dev tells us the sale price
     */

    function getSalePrice() external returns(uint256 price);

    /**
     * @dev Renames the NFT 'tokenId' with 'nftName'
     */

    function renameNFT(uint256 tokenId, string memory nftName) external; 

    /**
     * @dev Levels up the NFT with the given 'tokenId'
     */
    function levelUpNFT(uint256 tokenId) external;

     /**
     * @dev Unlocks the utility of the given 'tokenId' with slug 'utilitySlug'
     */


    function unlockUtility(uint256 tokenId, string memory utilitySlug) external;

    /**
     * @dev Levels up the NFT and unlocks the utility at a same time
     */
    function levelUpNFTWithUtility(uint256 tokenId, string memory utilitySlug) external;

    /**
     * @dev Unlocks or locks the utility for a tokenId based on previous state
     */
    function toggleUtility(uint256 tokenId, string memory utilitySlug) external;
}
