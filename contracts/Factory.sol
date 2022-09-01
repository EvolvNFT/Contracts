// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IXenonNFT.sol";
import "./interfaces/IFactory.sol";

import "./XenonNFT.sol";
import "hardhat/console.sol";

contract Factory is IFactory {

    address private owner;
    address private oracle;
    address private batchUpdateContract;

    struct Brand {
        string name;
        address owner;
        address treasury;
        bool isActive;
    }

    mapping (string => Brand) public brands;
    mapping (string => mapping(uint256 => address)) public collectionContract;
    mapping (string => uint256) public nextCollection;

    modifier onlyOracle {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBatchUpdateContract {
        require(msg.sender == batchUpdateContract);
        _;
    }

    constructor(address _owner, address _oracle) {
        console.log("Deploying a Factory with owner:", _owner);
        owner = _owner;
        oracle = _oracle;
    }

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
        ) public override onlyOwner{
            require(!brands[_brandId].isActive, "Brand already exists");
            
            console.log("Adding a brand with name '%s' owner '%s' and treasury '%s'", _brandName, _owner, _treasury);
            
            brands[_brandId] = Brand(_brandName, _owner, _treasury, true);
            _addCollectionToBrands(_brandId, _collectionName, _collectionSymbol, _treasury, _nftCount,_salePrice, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);

            emit BrandOnboarded(_brandId, _brandName, _owner, _treasury);
    }

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
        address _salesTokenAddress) public override onlyOracle{
        _addCollectionToBrands(_brandId, _collectionName, _collectionSymbol, _treasury, _nftCount,_salePrice, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);
    }

    function _addCollectionToBrands(
        string memory _brandId,
        string memory _collectionName,
        string memory _collectionSymbol,
        address _treasury,
        uint256 _nftCount,
        uint256 _salePrice,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress) internal virtual {
            address nftAddress = address(new LevelNFT(_collectionName, _collectionSymbol, _salePrice, _nftCount, _treasury, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress));
            console.log(nftAddress);

            uint256 nextCollectionId = nextCollection[_brandId];

            collectionContract[_brandId][nextCollectionId] = nftAddress;
            nextCollection[_brandId]++;

            emit CollectionAdded(_brandId, nextCollectionId, nftAddress, _collectionName, _collectionSymbol, _treasury, _nftCount, _salePrice, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);
    }

    function setBaseURI(address _nftAddress, string memory _URI, string memory _ext) public override onlyOracle{
        IXenonNFT nft = IXenonNFT(_nftAddress);
        nft.setBaseURI(_URI, _ext);
    }

    function levelUpNFTFactory(address _nftAddress, uint256 _tokenId) public override onlyOracle{
        IXenonNFT nft = IXenonNFT(_nftAddress);
        nft.levelUpNFT(_tokenId);
    }

    function unlockUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) public override onlyOracle{
        IXenonNFT nft = IXenonNFT(_nftAddress);
        nft.unlockUtility(_tokenId, _utilitySlug);
    }

    function levelUpNFTWithUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) public override onlyBatchUpdateContract{
        IXenonNFT nft = IXenonNFT(_nftAddress);
        nft.levelUpNFTWithUtility(_tokenId, _utilitySlug);
    }

    function toggleUtilityFactory(address _nftAddress, uint256 _tokenId, bytes32 _utilitySlug) public override onlyOracle{
        IXenonNFT nft = IXenonNFT(_nftAddress);
        nft.toggleUtility(_tokenId, _utilitySlug);
    }

    function setOracleFactory(address _oracle) public override onlyOwner{
        console.log("Changing oracle from '%s' to '%s'", oracle, _oracle);
        oracle = _oracle;

        emit OracleChanged( _oracle);
    }

    function changeAdminFactory(address _owner) public override onlyOwner{
        console.log("Changing admin from '%s' to '%s'", owner, _owner);
        owner = _owner;

        emit AdminChanged( _owner);
    }

    function changeBatchUpdateContractFactory(address _batchUpdateContract) public override onlyOwner{
        console.log("Changing batchUpdateContract from '%s' to '%s'", batchUpdateContract, _batchUpdateContract);
        batchUpdateContract = _batchUpdateContract;

        emit BatchUpdateContractChanged( _batchUpdateContract);
    }
}