// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract LevelNFT is ERC721Royalty {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private treasury;
    uint256 private salePrice;
    uint256 private salesStartBlock;
    uint256 private salesEndBlock;
    bool private isTokenSale;
    address private salesTokenAddress;
    address private factory;

    mapping (uint256 => string) public nftNames;
    mapping (uint256 => uint256) public nftLevels;

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

    modifier validateSalesTime {
        require(salesStartBlock <= block.number && salesEndBlock >= block.number);
        _;
    }

    modifier validateAfterSalesTime{
        require(salesEndBlock <= block.number);
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _salePrice,
        address _treasury,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress
        ) ERC721(_name, _symbol){

            require(block.number <= _salesStartBlock && _salesStartBlock < _salesEndBlock, "Sale Timings not applicable    ");

            salePrice = _salePrice;
            treasury = _treasury;
            salesStartBlock = _salesStartBlock;
            salesEndBlock = _salesEndBlock;
            isTokenSale = _isTokenSale;
            salesTokenAddress = _salesTokenAddress;

            factory = msg.sender;

            salesToken = IERC20(_salesTokenAddress);
    }

    function renameNFT(uint256 tokenId, string nftName) public onlyFactory {
        nftNames[tokenId] = nftName;
    }

    function levelUpNFT(uint256 tokenId) public onlyFactory {
        nftLevels[tokenId] += 1;
    }

    function unlockUtility(uint256 tokenId, string utilitySlug) public onlyFactory {
        utilities[tokenId][utilitySlug] = true;
    }

    function levelUpNFTWithUtility(uint256 tokenId, string utilitySlug) public onlyFactory{
        nftLevels[tokenId] += 1;
        utilities[tokenId][utilitySlug] = true;
    }

    function toggleUtility(uint256 tokenId, utilitySlug) public onlyFactory {
        utilities[tokenId][utilitySlug] = utilities[tokenId][utilitySlug] ? false : true;
    }

    function buyNFTWithEth() public payable validateSalesTime returns (uint256) {
        require( isTokenSale == false, "Sale is token-based");
        require(msg.value >= salePrice);

        uint256 newNFTId = _tokenIds.current();
        _safeMint(msg.sender, newNFTId);

        _tokenIds.increment();
        return newNFTId;
    }

    function buyNFTWithToken() public validateSalesTime returns (uint256) {
        require( isTokenSale == true, "Sale is eth-based");

        uint256 newNFTId = _tokenIds.current();
        _safeMint(msg.sender, newNFTId);

        _tokenIds.increment();

        salesToken.transferFrom(msg.sender, address(this), salePrice);
        return newNFTId;
    }

    function claimSalesEthAmount() public validateAfterSalesTime onlyTreasury {
        require( isTokenSale == false, "Sale is token-based");

        uint256 contractBalance = address(this).balance;
        address payable treasuryAddress = payable(treasury);
        if( contractBalance > 0 ) {
            treasuryAddress.transfer(contractBalance);
        }
    }

    function claimSalesTokenAmount() public onlyTreasury validateAfterSalesTime {
        require( isTokenSale == true, "Sale is eth-based");

        uint256 contractBalance = salesToken.balanceOf(address(this));
        if( contractBalance > 0 ) {
            salesToken.transfer(msg.sender, contractBalance);
        }
    }
}
