//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract LevelNFT is ERC721Royalty{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private treasury;

    uint256 public salePrice;

    modifier onlyTreasury {
        require(msg.sender == treasury);
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _salePrice, address _treasury) ERC721(_name, _symbol){
        salePrice = _salePrice;
        treasury = _treasury;
    }

    function buyNFT() public payable returns (uint256){
        require(msg.value >= salePrice);
        uint256 newNFTId = _tokenIds.current();
        super._safeMint(msg.sender, newNFTId);

        _tokenIds.increment();
        return newNFTId;
    }

    function claimSalesAmount() public onlyTreasury {
        uint256 contractBalance = address(this).balance;
        address payable treasuryAddress = payable(treasury);
        if( contractBalance > 0 ) {
            treasuryAddress.transfer(contractBalance);
        }
    }
}
