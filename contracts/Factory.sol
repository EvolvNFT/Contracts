// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IXenonNFT.sol";

import "./XenonNFT.sol";
import "hardhat/console.sol";

contract Factory {

    address private owner;
    address private oracle;
    address private batchUpdateContract;
    struct Brand {
        string name;
        address owner;
        address treasury;
        address nftContract;
        bool isActive;
    }

    mapping (string => Brand) public brands;

    mapping (address => uint256) addressLevels;

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
        address _owner,
        address _treasury,
        uint256 _nftCount,
        uint256 _salePrice,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress
        ) public onlyOwner{
            require(!brands[_brandId].isActive, "Brand already exists");
            
            console.log("Adding a brand with name '%s' owner '%s' and treasury '%s'", _brandName, _owner, _treasury);
            address nftAddress = address(new LevelNFT(_brandId, _brandName, _salePrice, _nftCount, _treasury, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress));
            console.log(nftAddress);

            brands[_brandId] = Brand(_brandName, _owner, _treasury, nftAddress, true);
    }

    function onboardBrandWithExistingNFTs(
        string memory _brandId,
        string memory _brandName,
        address _owner,
        address _treasury,
        address nftAddress
        ) public onlyOwner{
            require(!brands[_brandId].isActive, "Brand already exists");
            console.log("Adding a brand with name '%s' owner '%s' and treasury '%s'", _brandName, _owner, _treasury);

            brands[_brandId] = Brand(_brandName, _owner, _treasury, nftAddress, true);
    }

    function levelUpNFT(address nftAddress, uint256 tokenId) public onlyOracle{
        IXenonNFT nft = IXenonNFT(nftAddress);
        nft.levelUpNFT(tokenId);
    }

    function addCollection(address nftAddress,uint256 newCollectionCount, uint256 price, uint256 salesStartBlock, uint256 salesEndBlock, bool isTokenSale, address salesTokenAddress) public onlyOracle{
        IXenonNFT nft = IXenonNFT(nftAddress);
        nft.addCollection(newCollectionCount, price, salesStartBlock, salesEndBlock, isTokenSale, salesTokenAddress);
    }

    function unlockUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) public onlyOracle{
        IXenonNFT nft = IXenonNFT(nftAddress);
        nft.unlockUtility(tokenId, utilitySlug);
    }

    function levelUpNFTWithUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) public onlyBatchUpdateContract{
        IXenonNFT nft = IXenonNFT(nftAddress);
        nft.levelUpNFTWithUtility(tokenId, utilitySlug);
    }

    function toggleUtility(address nftAddress, uint256 tokenId, string memory utilitySlug) public onlyOracle{
        IXenonNFT nft = IXenonNFT(nftAddress);
        nft.toggleUtility(tokenId, utilitySlug);
    }

    function setOracle(address _oracle) public onlyOwner{
        console.log("Changing oracle from '%s' to '%s'", oracle, _oracle);
        oracle = _oracle;
    }

    function changeAdmin(address _admin) public onlyOwner{
        console.log("Changing admin from '%s' to '%s'", owner, _admin);
        owner = _admin;
    }

    function changeBatchUpdateContract(address _batchUpdateContract) public onlyOwner{
        console.log("Changing batchUpdateContract from '%s' to '%s'", batchUpdateContract, _batchUpdateContract);
        batchUpdateContract = _batchUpdateContract;
    }
}
