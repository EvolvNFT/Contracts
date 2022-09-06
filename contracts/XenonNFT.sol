// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LevelXenonNFT.sol";

contract LevelNFT is LevelXenonNFT {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private treasury;
    uint256 private salePrice;
    uint256 private nftCount;
    uint256 private salesStartBlock;
    uint256 private salesEndBlock;
    bool private isTokenSale;
    address private salesTokenAddress;
    IERC20 salesToken;

    modifier onlyTreasury {
        require(msg.sender == treasury);
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
        ) LevelXenonNFT(_name, _symbol){

            require(block.number <= _salesStartBlock && _salesStartBlock < _salesEndBlock, "Sale Timings not applicable");

            salePrice = _salePrice;
            nftCount = _nftCount;
            treasury = _treasury;
            salesStartBlock = _salesStartBlock;
            salesEndBlock = _salesEndBlock;
            isTokenSale = _isTokenSale;
            salesTokenAddress = _salesTokenAddress;

            salesToken = IERC20(_salesTokenAddress);
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