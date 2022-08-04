// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an Xenon Factory compliant contract.
 */
interface IFactory {

    /**
     * @dev Onboards a new brand to the platform and launches an NFT contract
     */
    function onboardBrand(
        string memory _brandId,
        string memory _brandName,
        address _owner,
        address _treasury,
        uint256 _nftCount,
        uint256 _salePrice,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress
    ) external; 

    /**
     * @dev Onboards a brand with existing NFT
     */
    function onboardBrandWithExistingNFTs(
        string memory _brandId,
        string memory _brandName,
        address _owner,
        address _treasury,
        address nftAddress
    ) external;

    /**
     * @dev Level Up the NFT
     */
    function levelUpNFT(address nftAddress, uint256 tokenId) external;

    /**
     * @dev Add collection of the NFT contract
     */
    function addCollection(address nftAddress, uint256 newCollectionCount, uint256 price, uint256 salesStartBlock, uint256 salesEndBlock, bool isTokenSale, address salesTokenAddress) external;

    /**
     * @dev Unlock the utility of the NFT
     */
    function unlockUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) external;

    /**
     * @dev Level up the NFT and unlock utility
     */
    function levelUpNFTWithUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) external;

    /**
     * @dev Change the utility of the NFT - unlock/lock
     */
    function toggleUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) external;

    /**
     * @dev Set the oracle address of the contract
     */
    function setOracle(address _oracle) external;

    /**
     * @dev Set new admin of contract
     */
    function changeAdmin(address _admin) external;
}
