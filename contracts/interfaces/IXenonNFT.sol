// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an XenonNFT compliant contract.
 */
interface XenonNFT {

    /**
     * @dev Renames the NFT 'tokenId' with 'nftName'
     */
    function renameNFT(uint256 tokenId, string nftName) external; 

    /**
     * @dev Levels up the NFT with the given 'tokenId'
     */
    function levelUpNFT(uint256 tokenId) external;

    /**
     * @dev Unlocks the utility of the given 'tokenId' with slug 'utilitySlug'
     */
    function unlockUtility(uint256 tokenId, string utilitySlug) external;

    /**
     * @dev Levels up the NFT and unlocks the utility at a same time
     */
    function levelUpNFTWithUtility(uint256 tokenId, string utilitySlug) external;

    /**
     * @dev Unlocks or locks the utility for a tokenId based on previous state
     */
    function toggleUtility(uint256 tokenId, string utilitySlug) external;

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
     * @dev Transfers sales ETH to the treasury of the brand
     */
    function claimSalesEthAmount() external;

    /**
     * @dev Transfers sales Token to the treasury of the brand
     */
    function claimSalesTokenAmount() external;
}
