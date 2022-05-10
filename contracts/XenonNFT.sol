//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

            salesToken = IERC20(_salesTokenAddress);
    }

    function buyNFTWithEth() public payable validateSalesTime returns (uint256) {
        require( isTokenSale == false, "Sale is token-based");
        require(msg.value >= salePrice);

        uint256 newNFTId = _tokenIds.current();
        super._safeMint(msg.sender, newNFTId);

        _tokenIds.increment();
        return newNFTId;
    }

    function buyNFTWithToken() public validateSalesTime returns (uint256) {
        require( isTokenSale == true, "Sale is eth-based");

        uint256 newNFTId = _tokenIds.current();
        super._safeMint(msg.sender, newNFTId);

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
