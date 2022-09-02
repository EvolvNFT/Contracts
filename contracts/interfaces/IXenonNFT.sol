// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an XenonNFT compliant contract.
 */
interface IXenonNFT {

    event NFTRenamed(uint256 indexed tokenId, string nftName);
    event NFTLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event UtilityUnlocked(uint256 indexed tokenId, bytes32 utilitySlug);
    event NFTClaimed(uint256 indexed tokenId, uint256 price, address owner);
    event NFTUtilityLevelUp(uint256 indexed tokenId, uint256 newLevel, bytes32 utilitySlug);
    event URIUpdated(string uri, string extension);

    /**
     * @dev Renames the NFT 'tokenId' with 'nftName'
     */
    function renameNFT(uint256 _tokenId, string memory _nftName) external; 

    /**
     * @dev Set Base URI
     */
    function setBaseURI(string memory _URI, string memory _ext) external;

    /**
     * @dev Levels up the NFT with the given 'tokenId'
     */
    function levelUpNFT(uint256 _tokenId) external;

    /**
     * @dev Unlocks the utility of the given 'tokenId' with slug 'utilitySlug'
     */
    function unlockUtility(uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Levels up the NFT and unlocks the utility at a same time
     */
    function levelUpNFTWithUtility(uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Unlocks or locks the utility for a tokenId based on previous state
     */
    function toggleUtility(uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Transfers NFT to the user by deducting sales price ETH
     * 
     * Requirements:
     *
     * - The sales need to be in ETH
     */
    function buyNFTWithEth() external payable;

    /**
     * @dev Transfers NFT to the user by deducting sales price Token
     *
     * Requirements:
     *
     * - The sales need to be in token
     */
    function buyNFTWithToken() external;

    /**
     * @dev Transfers sales ETH to the treasury of the brand
     */
    function claimSalesEthAmount() external;

    /**
     * @dev Transfers sales Token to the treasury of the brand
     */
    function claimSalesTokenAmount(address _tokenAddress) external;
}