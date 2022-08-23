// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract LevelNFT is ERC721Royalty {

    uint256 private collection_id;

    address private treasury;
    address private factory;

    struct Collection {
        uint256 salePrice;
        uint256 startNftId;
        uint256 nftCount;
        uint256 salesStartBlock;
        uint256 salesEndBlock;
        bool isTokenSale;
        address salesTokenAddress;
    }

    mapping (uint256 => bytes32) public nftNames;
    mapping (uint256 => uint256) public nftLevels;
    mapping (uint256 => Collection) public collections;
    mapping (uint256 => uint256) public nextNftOfCollection;
    mapping (uint256 => mapping( bytes32 => bool)) public utilities;

    IERC20 salesToken;

    modifier onlyTreasury {
        require(msg.sender == treasury);
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factory);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _salePrice,
        uint256 _nftCount,
        address _treasury,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress
        ) ERC721(_name, _symbol){

            require(block.number <= _salesStartBlock && _salesStartBlock < _salesEndBlock, "Sale Timings not applicable");

            treasury = _treasury;
            factory = msg.sender;

            collections[0] = Collection(_salePrice, 0, _nftCount, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);
            nextNftOfCollection[0] = 0;
            collection_id = 1;
    }

    function renameNFT(uint256 _tokenId, bytes32 _nftName) public onlyFactory {
        nftNames[_tokenId] = _nftName;
    }

    function levelUpNFT(uint256 _tokenId) public onlyFactory {
        nftLevels[_tokenId] += 1;
    }

    function unlockUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory {
        utilities[_tokenId][_utilitySlug] = true;
    }

    function levelUpNFTWithUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory{
        nftLevels[_tokenId] += 1;
        utilities[_tokenId][_utilitySlug] = true;
    }

    function toggleUtility(uint256 _tokenId, bytes32 _utilitySlug) public onlyFactory {
        utilities[_tokenId][_utilitySlug] = utilities[_tokenId][_utilitySlug] ? false : true;
    }

    function buyNFTWithEth(uint256 _collectionId) public payable returns (uint256) {
        require( collections[_collectionId].isTokenSale == false, "Sale is token-based");
        require(collections[_collectionId].salesStartBlock <= block.number && collections[_collectionId].salesEndBlock >= block.number, "Not sales time");
        require(msg.value >= collections[_collectionId].salePrice, "Amount not sufficient");

        uint256 newNFTId = nextNftOfCollection[_collectionId]+ collections[_collectionId].startNftId;
        require(newNFTId < collections[_collectionId].startNftId + collections[_collectionId].nftCount, "No NFT to mint in the collection");
        
        nextNftOfCollection[_collectionId]++;

        _safeMint(msg.sender, newNFTId);
        return newNFTId;
    }

    function buyNFTWithToken(uint256 _collectionId) public returns (uint256) {
        require( collections[_collectionId].isTokenSale == true, "Sale is eth-based");
        require(collections[_collectionId].salesStartBlock <= block.number && collections[_collectionId].salesEndBlock >= block.number, "Not sales time");

        uint256 newNFTId = nextNftOfCollection[_collectionId] + collections[_collectionId].startNftId;
        require(newNFTId < collections[_collectionId].startNftId + collections[_collectionId].nftCount, "No NFT to mint in the collection");

        salesToken = IERC20(collections[_collectionId].salesTokenAddress);
        nextNftOfCollection[_collectionId]++;

        _safeMint(msg.sender, newNFTId);
        salesToken.transferFrom(msg.sender, address(this), collections[_collectionId].salePrice);
        return newNFTId;
    }

    function addCollection(
                uint256 _newCollectionCount,
                uint256 _price,
                uint256 _salesStartBlock,
                uint256 _salesEndBlock,
                bool _isTokenSale,
                address _salesTokenAddress) public onlyFactory {
        uint256 nextCollectionStartId = collections[collection_id - 1].startNftId + collections[collection_id - 1].nftCount;
        collections[collection_id] = Collection(_price, nextCollectionStartId, _newCollectionCount, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);
        collection_id++;
    }

    function claimSalesEthAmount() public onlyTreasury {
        uint256 contractBalance = address(this).balance;
        address payable treasuryAddress = payable(treasury);
        if( contractBalance > 0 ) {
            treasuryAddress.transfer(contractBalance);
        }
    }

    function claimSalesTokenAmount(address _tokenAddress) public onlyTreasury {
        salesToken = IERC20(_tokenAddress);

        uint256 contractBalance = salesToken.balanceOf(address(this));
        if( contractBalance > 0 ) {
            salesToken.transfer(msg.sender, contractBalance);
        }
    }
}
