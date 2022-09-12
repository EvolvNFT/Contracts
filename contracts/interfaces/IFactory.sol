// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an Xenon Factory compliant contract.
 */
interface IFactory {

    event BrandOnboarded(string brandId, string brandName, address owner, address treasury);
    event CollectionAdded(
        string brandId,
        uint256 collectionId,
        address nftContract,
        string collectionName,
        string collectionSymbol,
        address treasury,
        uint256 nftCount,
        uint256 salePrice,
        uint256 salesStartBlock,
        uint256 salesEndBlock,
        bool isTokenSale,
        address salesTokenAddress);
    event AdminChanged( address owner);
    event BatchUpdateContractChanged(address batchUpdateContract);
    event OracleChanged(address oracle);

    /**
     * @dev Onboards a new brand to the platform and launches an NFT contract
     */
    function onboardBrand(
        string memory _brandId,
        string memory _brandName,
        string memory _collectionName,
        string memory _collectionSymbol,
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
     * @dev Level Up the NFT
     */
    function levelUpNFTFactory(address _nftAddress, uint256 _tokenId) external;

    /**
     * @dev Add collection of the NFT contract
     */
    function addCollection(
        string memory _brandId,
        string memory _collectionName,
        string memory _collectionSymbol,
        address _treasury,
        uint256 _nftCount,
        uint256 _salePrice,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress) external;

    /**
     * @dev Set Base URI for the NFT
     */
    function setBaseURI(address _nftAddress, string memory _URI, string memory _ext) external;

    /**
     * @dev Unlock the utility of the NFT
     */
    function unlockUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Level up the NFT and unlock utility
     */
    function levelUpNFTWithUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Change the utility of the NFT - unlock/lock
     */
    function toggleUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) external;

    /**
     * @dev Set the oracle address of the contract
     */
    function setOracleFactory(address _oracle) external;

    /**
     * @dev Set new owner of contract
     */
    function changeAdminFactory(address _owner) external;

    /**
     * @dev Set new batch update contract
     */
    function changeBatchUpdateContractFactory(address _batchUpdateContract) external;
}