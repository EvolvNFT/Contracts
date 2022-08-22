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

    mapping (uint256 => string) public nftNames;
    mapping (uint256 => uint256) public nftLevels;
    mapping (uint256 => Collection) public collections;
    mapping (uint256 => uint256) public nextNftOfCollection;
    mapping (uint256 => mapping( string => bool)) public utilities;

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

    function renameNFT(uint256 tokenId, string memory nftName) public onlyFactory {
        nftNames[tokenId] = nftName;
    }

    function levelUpNFT(uint256 tokenId) public onlyFactory {
        nftLevels[tokenId] += 1;
    }

    function unlockUtility(uint256 tokenId, string memory utilitySlug) public onlyFactory {
        utilities[tokenId][utilitySlug] = true;
    }

    function levelUpNFTWithUtility(uint256 tokenId, string memory utilitySlug) public onlyFactory{
        nftLevels[tokenId] += 1;
        utilities[tokenId][utilitySlug] = true;
    }

    function toggleUtility(uint256 tokenId, string memory utilitySlug) public onlyFactory {
        utilities[tokenId][utilitySlug] = utilities[tokenId][utilitySlug] ? false : true;
    }

    function buyNFTWithEth(uint256 collectionId) public payable returns (uint256) {
        require( collections[collectionId].isTokenSale == false, "Sale is token-based");
        require(collections[collectionId].salesStartBlock <= block.number && collections[collectionId].salesEndBlock >= block.number, "Not sales time");
        require(msg.value >= collections[collectionId].salePrice, "Amount not sufficient");

        uint256 newNFTId = nextNftOfCollection[collectionId]+ collections[collectionId].startNftId;
        require(newNFTId < collections[collectionId].startNftId + collections[collectionId].nftCount, "No NFT to mint in the collection");
        
        nextNftOfCollection[collectionId]++;

        _safeMint(msg.sender, newNFTId);
        return newNFTId;
    }

    function buyNFTWithToken(uint256 collectionId) public returns (uint256) {
        require( collections[collectionId].isTokenSale == true, "Sale is eth-based");
        require(collections[collectionId].salesStartBlock <= block.number && collections[collectionId].salesEndBlock >= block.number, "Not sales time");

        uint256 newNFTId = nextNftOfCollection[collectionId] + collections[collectionId].startNftId;
        require(newNFTId < collections[collectionId].startNftId + collections[collectionId].nftCount, "No NFT to mint in the collection");

        salesToken = IERC20(collections[collectionId].salesTokenAddress);
        nextNftOfCollection[collectionId]++;

        _safeMint(msg.sender, newNFTId);
        salesToken.transferFrom(msg.sender, address(this), collections[collectionId].salePrice);
        return newNFTId;
    }

    function addCollection(uint256 _newCollectionCount, uint256 price, uint256 _salesStartBlock, uint256 _salesEndBlock, bool _isTokenSale, address _salesTokenAddress) public onlyFactory {
        uint256 nextCollectionStartId = collections[collection_id - 1].startNftId + collections[collection_id - 1].nftCount;
        collections[collection_id] = Collection(price, nextCollectionStartId, _newCollectionCount, _salesStartBlock, _salesEndBlock, _isTokenSale, _salesTokenAddress);
        collection_id++;
    }

    function claimSalesEthAmount() public onlyTreasury {
        uint256 contractBalance = address(this).balance;
        address payable treasuryAddress = payable(treasury);
        if( contractBalance > 0 ) {
            treasuryAddress.transfer(contractBalance);
        }
    }

    function claimSalesTokenAmount(address tokenAddress) public onlyTreasury {
        salesToken = IERC20(tokenAddress);

        uint256 contractBalance = salesToken.balanceOf(address(this));
        if( contractBalance > 0 ) {
            salesToken.transfer(msg.sender, contractBalance);
        }
    }
}
