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
        address _nftAddress
    ) external;

    /**
     * @dev Level Up the NFT
     */
    function levelUpNFT(address _nftAddress, uint256 _tokenId) external;

    /**
     * @dev Add collection of the NFT contract
     */
    function addCollection(address _nftAddress, uint256 _newCollectionCount, uint256 _price, uint256 _salesStartBlock, uint256 _salesEndBlock, bool _isTokenSale, address _salesTokenAddress) external;

    /**
     * @dev Unlock the utility of the NFT
     */
    function unlockUtility(address _nftAddress, uint256 _tokenId, string memory _utilitySlug) external;

    /**
     * @dev Level up the NFT and unlock utility
     */
    function levelUpNFTWithUtility(address _nftAddress, uint256 _tokenId, string memory _utilitySlug) external;

    /**
     * @dev Change the utility of the NFT - unlock/lock
     */
    function toggleUtility(address _nftAddress, uint256 _tokenId, string memory _utilitySlug) external;

    /**
     * @dev Set the oracle address of the contract
     */
    function setOracle(address _oracle) external;

    /**
     * @dev Set new owner of contract
     */
    function changeAdmin(address _owner) external;
}
