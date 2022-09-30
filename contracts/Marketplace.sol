// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IXenonNFT.sol";

import "./XenonNFT.sol";
import "./Factory.sol";
import "hardhat/console.sol";

contract MarketPlace {

    address payable treasury;

    constructor(address payable _treasury){
        treasury=_treasury;
    }

    mapping(address=>uint256) userBalance;
    
    struct NFT{
        uint256 salePrice;
        uint256 endTime;
        address payable owner;
        address payable buyer;
        bool onSale;
        bool isEthSale;
        address salesTokenAddress;        
    }

    mapping(address=>mapping(uint256=>NFT)) NFTs; //store details of NFT on auction

    bool internal locked;

    modifier noReentrant() {
        require(!locked,"No re-entrancy");
        locked=true;
        _;
        locked=false;
    }

    function listNFTforSale(address nftAddress, uint256 tokenID, uint256 _endTime, uint256 salePrice, bool _isETHSale, address _salesTokenAddress) public{
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==nft.ownerOf(tokenID),"Error: You must be the owner of NFT");
        require(NFTs[nftAddress][tokenID].onSale==false,'Error: The NFT is already on Sale');

        nft.transferFrom(msg.sender, address(this), tokenID);

        NFTs[nftAddress][tokenID].salePrice = salePrice;
        NFTs[nftAddress][tokenID].endTime = _endTime;
        NFTs[nftAddress][tokenID].owner = payable(msg.sender);
        NFTs[nftAddress][tokenID].onSale = true;
        NFTs[nftAddress][tokenID].isEthSale = _isETHSale;
        NFTs[nftAddress][tokenID].salesTokenAddress = _salesTokenAddress;
    }

    function revertNFTfromSale(address nftAddress, uint256 tokenID) public{
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==NFTs[nftAddress][tokenID].owner,'Error: You must be the owner of NFT');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT must be on sale to cancel listing');
        
        nft.transferFrom(address(this),msg.sender,tokenID);

        NFTs[nftAddress][tokenID].onSale=false;
    }


    function buyWithETH(address nftAddress, uint256 tokenID) public payable{
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(NFTs[nftAddress][tokenID].owner!=msg.sender,'Error: The owner cannot buy the NFT');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Error: Please switch to token Sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT is not listed on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Error: The Sale for NFT has ended');

        require(msg.value>=NFTs[nftAddress][tokenID].salePrice,"Error: Does not meet the Sale Price Cost");

        NFTs[nftAddress][tokenID].buyer = payable(msg.sender);

        userBalance[NFTs[nftAddress][tokenID].owner]+=((msg.value)*(95))/100;
        userBalance[treasury]+=((msg.value)*(5))/100;

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].buyer,tokenID);

    }

    function buyWithToken(address nftAddress, uint256 tokenID) public{
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(NFTs[nftAddress][tokenID].owner!=msg.sender,'Error: The owner cannot buy the NFT');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Error: Please switch to token Sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Error: NFT is not listed on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Error: The Sale for NFT has ended');

        IERC20 salesToken = IERC20(NFTs[nftAddress][tokenID].salesTokenAddress);
            
        require(salesToken.balanceOf(msg.sender)>=NFTs[nftAddress][tokenID].salePrice,'Error: value sent is lower than minimum cost');
            
        userBalance[NFTs[nftAddress][tokenID].owner]+=(salesToken.balanceOf(address(this))*95)/100;
        userBalance[treasury]+=(salesToken.balanceOf(address(this))*5)/100;
        userBalance[NFTs[nftAddress][tokenID].buyer]+=salesToken.balanceOf(address(this));

        NFTs[nftAddress][tokenID].buyer=payable(msg.sender);

        salesToken.transferFrom(msg.sender, address(this), NFTs[nftAddress][tokenID].salePrice);

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].buyer,tokenID);

    }

    function withdrawYourETH() public{
        uint256 balance = userBalance[msg.sender];
        require(balance>0,'Error: There is no ETH to transfer');

        address payable _treasuryAddress = payable(msg.sender);

        (bool _sent,) = _treasuryAddress.call{value: balance}("");
        require(_sent, "Error: Failed to send Ether");

        userBalance[msg.sender]=0;
    }

    function withdrawYourToken(address _salesToken) public{
        IERC20 salesToken = IERC20(_salesToken);

        uint256 _contractBalance = salesToken.balanceOf(msg.sender);
        require( _contractBalance > 0 , "Error: No Token accumulated");
        salesToken.transfer(msg.sender, _contractBalance);

    }

    function getBalance() public view returns(uint256){
        return userBalance[msg.sender];
    }

}