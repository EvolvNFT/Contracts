// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

import "./interfaces/IXenonNFT.sol";

contract LevelNFT is ERC721Royalty, IXenonNFT {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private treasury;
    uint256 private salePrice;
    uint256 private nftCount;
    uint256 private salesStartBlock;
    uint256 private salesEndBlock;
    bool private isTokenSale;
    address private salesTokenAddress;
    address private factory;

    string private URI;
    string private extension;

    mapping (uint256 => string) public nftNames;
    mapping (uint256 => uint256) public nftLevels;

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
        uint256 _nftCount,
        address _treasury,
        uint256 _salesStartBlock,
        uint256 _salesEndBlock,
        bool _isTokenSale,
        address _salesTokenAddress
        ) ERC721(_name, _symbol){

            require(block.number <= _salesStartBlock && _salesStartBlock < _salesEndBlock, "Sale Timings not applicable");

            salePrice = _salePrice;
            nftCount = _nftCount;
            treasury = _treasury;
            salesStartBlock = _salesStartBlock;
            salesEndBlock = _salesEndBlock;
            isTokenSale = _isTokenSale;
            salesTokenAddress = _salesTokenAddress;

            factory = msg.sender;

            salesToken = IERC20(_salesTokenAddress);
    }

    function setBaseURI(string memory _URI, string memory _ext) public override onlyFactory {
        URI = _URI;
        extension = _ext;

        emit URIUpdated(_URI, _ext);
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        string memory _baseWithTokenID = super.tokenURI(_tokenId);
        return bytes(_baseWithTokenID).length > 0 ? string(abi.encodePacked(_baseWithTokenID, extension)) : "";
    }

    function renameNFT(uint256 _tokenId, string memory _nftName) public override onlyFactory {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        nftNames[_tokenId] = _nftName;

        emit NFTRenamed(_tokenId, _nftName);
    }

    function levelUpNFT(uint256 _tokenId) public override onlyFactory {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        nftLevels[_tokenId] += 1;

        emit NFTLeveledUp(_tokenId, nftLevels[_tokenId]);
    }

    function unlockUtility(uint256 _tokenId, bytes32 _utilitySlug) public override onlyFactory {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        utilities[_tokenId][_utilitySlug] = true;

        emit UtilityUnlocked(_tokenId, _utilitySlug);
    }

    function levelUpNFTWithUtility(uint256 _tokenId, bytes32 _utilitySlug) public override onlyFactory{
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        nftLevels[_tokenId] += 1;
        utilities[_tokenId][_utilitySlug] = true;

        emit NFTUtilityLevelUp(_tokenId, nftLevels[_tokenId], _utilitySlug);
    }

    function toggleUtility(uint256 _tokenId, bytes32 _utilitySlug) public override onlyFactory {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        utilities[_tokenId][_utilitySlug] = utilities[_tokenId][_utilitySlug] ? false : true;
    }

    function buyNFTWithEth() public payable override validateSalesTime {
        require( isTokenSale == false, "Sale is token-based");
        require(msg.value >= salePrice);

        _buyNFT();
    }

    function buyNFTWithToken() public override validateSalesTime {
        require( isTokenSale == true, "Sale is eth-based");

        _buyNFT();
        salesToken.transferFrom(msg.sender, address(this), salePrice);
    }

    function _buyNFT() internal virtual {
        require(salesStartBlock <= block.number && salesEndBlock >= block.number, "Not sales time");

        uint256 _newNFTId = _tokenIds.current();
        require(_newNFTId < nftCount, "No NFT to mint");

        _tokenIds.increment();
        _safeMint(msg.sender, _newNFTId);

        emit NFTClaimed(_newNFTId, salePrice, msg.sender);
    }

    function claimSalesEthAmount() public override onlyTreasury {
        uint256 _contractBalance = address(this).balance;
        require( _contractBalance > 0 , "No ETH accumulated");
        address payable _treasuryAddress = payable(treasury);

        (bool _sent,) = _treasuryAddress.call{value: _contractBalance}("");
        require(_sent, "Failed to send Ether");
    }

    function claimSalesTokenAmount(address _tokenAddress) public override onlyTreasury {
        salesToken = IERC20(_tokenAddress);

        uint256 _contractBalance = salesToken.balanceOf(address(this));
        require( _contractBalance > 0 , "No Token accumulated");
        salesToken.transfer(msg.sender, _contractBalance);
    }
}