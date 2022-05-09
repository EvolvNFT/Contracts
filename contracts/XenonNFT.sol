//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract LevelNFT is ERC721Royalty{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private treasury;
    uint256 private salePrice;
    uint256 private salesStartBlock;
    uint256 private salesEndBlock;

    modifier onlyTreasury {
        require(msg.sender == treasury);
        _;
    }

    modifier validateSalesTime{
        require(salesStartBlock <= block.number && salesEndBlock >= block.number);
        _;
    }

    modifier validateAfterSalesTime{
        require(salesEndBlock <= block.number);
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _salePrice, address _treasury, uint256 _salesStartBlock, uint256 _salesEndBlock) ERC721(_name, _symbol){
        salePrice = _salePrice;
        treasury = _treasury;
        salesStartBlock = _salesStartBlock;
        salesEndBlock = _salesEndBlock;
    }

    function buyNFT() public payable returns (uint256) validateSalesTime{
        require(msg.value >= salePrice);
        uint256 newNFTId = _tokenIds.current();
        super._safeMint(msg.sender, newNFTId);

        _tokenIds.increment();
        return newNFTId;
    }

    function claimSalesAmount() public onlyTreasury validateAfterSalesTime{
        uint256 contractBalance = address(this).balance;
        address payable treasuryAddress = payable(treasury);
        if( contractBalance > 0 ) {
            treasuryAddress.transfer(contractBalance);
        }
    }
}
