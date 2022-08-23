// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an XenonNFT compliant contract.
 */
interface IXenonNFT {

    /**
     * @dev Renames the NFT '_tokenId' with '_nftName'
     */
    function renameNFT(uint256 _tokenId, bytes32 _nftName) external; 

    /**
     * @dev Levels up the NFT with the given '_tokenId'
     */
    function levelUpNFT(uint256 _tokenId) external;

    /**
     * @dev Unlocks the utility of the given '_tokenId' with slug '_utilitySlug'
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
    function buyNFTWithEth() external returns (uint256);

    /**
     * @dev Transfers NFT to the user by deducting sales price Token
     *
     * Requirements:
     *
     * - The sales need to be in token
     */
    function buyNFTWithToken() external returns (uint256);

    /**
     * @dev Adds a new collection to the NFT
     *
     */
    function addCollection(uint256 _newCollectionCount, uint256 _price, uint256 _salesStartBlock, uint256 _salesEndBlock, bool _isTokenSale, address _salesTokenAddress) external;

    /**
     * @dev Transfers sales ETH to the treasury of the brand
     */
    function claimSalesEthAmount() external;

    /**
     * @dev Transfers sales Token to the treasury of the brand
     */
    function claimSalesTokenAmount() external;
}
