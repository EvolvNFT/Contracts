// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


import "./interfaces/IXenonNFT.sol";

import "./XenonNFT.sol";
import "./Factory.sol";
import "hardhat/console.sol";

contract MarketPlace {

    mapping(address=>uint256) balancesOfNFT;
    mapping(address=>uint256) userBalance;
    
    struct NFT{
        uint256 minPrice;
        uint256 endTime;
        uint256 bid;
        address payable seller;
        address payable bidder; 
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

    function listOnAuction(address nftAddress, uint256 tokenID, uint256 _endTime, uint256 salePrice,bool _isETHSale, address _salesTokenAddress) public{
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==nft.ownerOf(tokenID));
        require(NFTs[nftAddress][tokenID].onSale==false,'Already on Sale');

        nft.transferFrom(msg.sender, address(this), tokenID);

        NFTs[nftAddress][tokenID].minPrice = salePrice;
        NFTs[nftAddress][tokenID].endTime = _endTime;
        NFTs[nftAddress][tokenID].bid = 0;
        NFTs[nftAddress][tokenID].seller = payable(msg.sender);
        NFTs[nftAddress][tokenID].onSale = true;
        NFTs[nftAddress][tokenID].isEthSale = _isETHSale;
        NFTs[nftAddress][tokenID].salesTokenAddress = _salesTokenAddress;
    }

    function withdrawFromAuction(address nftAddress, uint256 tokenID) public{
        
        IXenonNFT nft = IXenonNFT(nftAddress);

        require(msg.sender==nft.ownerOf(tokenID));
        require(NFTs[nftAddress][tokenID].onSale==true,'NFT is not on sale');

        nft.transferFrom(address(this),msg.sender,tokenID);

        delete NFTs[nftAddress][tokenID];
    }


    function bidWithETH(address nftAddress, uint256 tokenID) public payable{
        IERC721 nft = IERC721(nftAddress);

        require(nft.ownerOf(tokenID)!=msg.sender,'owner cannot bid');
        require(NFTs[nftAddress][tokenID].isEthSale==true,'Not ETH sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Not on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Sale ended');

            if(NFTs[nftAddress][tokenID].bid==0){
                require(msg.value>=NFTs[nftAddress][tokenID].minPrice,'value sent is lower than minimum first bid');
            }
            else{
                require(msg.value>NFTs[nftAddress][tokenID].bid,'value sent is lower than current bid');
            }
            userBalance[NFTs[nftAddress][tokenID].seller]+=msg.value;
            NFTs[nftAddress][tokenID].bidder=payable(msg.sender);
            NFTs[nftAddress][tokenID].bid=msg.value;
    }

    function bidWithToken(address nftAddress, uint256 tokenID) public payable{
        IERC721 nft = IERC721(nftAddress);

        require(nft.ownerOf(tokenID)!=msg.sender,'owner cannot bid');
        require(NFTs[nftAddress][tokenID].isEthSale==false,'not a token based sale');
        require(NFTs[nftAddress][tokenID].onSale==true,'Not on Sale');
        require(NFTs[nftAddress][tokenID].endTime>block.timestamp, 'Sale ended');

            IERC20 salesToken = IERC20(NFTs[nftAddress][tokenID].salesTokenAddress);
            
            if(NFTs[nftAddress][tokenID].bid==0){
                require(salesToken.balanceOf(msg.sender)>=NFTs[nftAddress][tokenID].minPrice,'value sent is lower than minimum first bid');
            }
            else{
                require(salesToken.balanceOf(msg.sender)>NFTs[nftAddress][tokenID].bid,'value sent is lower than current bid');
            }
            userBalance[NFTs[nftAddress][tokenID].seller]+=salesToken.balanceOf(address(this));
            NFTs[nftAddress][tokenID].bidder=payable(msg.sender);
            NFTs[nftAddress][tokenID].bid=salesToken.balanceOf(msg.sender);

            salesToken.transferFrom(msg.sender, address(this), NFTs[nftAddress][tokenID].bid);

    }

    function claim(address nftAddress, uint256 tokenID) public noReentrant{

        IERC721 nft = IERC721(nftAddress);

        require(msg.sender==NFTs[nftAddress][tokenID].bidder,'You are not the hightest bidder');
        require(NFTs[nftAddress][tokenID].onSale==true,'Not on Sale');
        require(NFTs[nftAddress][tokenID].endTime<block.timestamp, 'Sale has not ended');

        NFTs[nftAddress][tokenID].onSale=false;

        nft.transferFrom(address(this),NFTs[nftAddress][tokenID].bidder,tokenID);

        _transfer(NFTs[nftAddress][tokenID].seller, NFTs[nftAddress][tokenID].bidder, nftAddress, tokenID);

        userBalance[NFTs[nftAddress][tokenID].seller]+=NFTs[nftAddress][tokenID].bid;
        userBalance[NFTs[nftAddress][tokenID].bidder]-=NFTs[nftAddress][tokenID].bid;

    }

    function _transfer(address from, address to, address nftAddress, uint256 tokenID) internal {
        require(to!= address(0));
        require(NFTs[nftAddress][tokenID].onSale == false);  // not transfer NFT if it is listed on Auction

        balancesOfNFT[from]--;
        balancesOfNFT[to]++;

    }

    function withDrawETH() public{
        uint256 balance = userBalance[msg.sender];
        require(balance>0,'There is no ETH to transfer');

        address payable _treasuryAddress = payable(msg.sender);

        (bool _sent,) = _treasuryAddress.call{value: balance}("");
        require(_sent, "Failed to send Ether");

        userBalance[msg.sender]=0;
    }

    function withdrawToken(address _salesToken) public{
        IERC20 salesToken = IERC20(_salesToken);

        uint256 _contractBalance = salesToken.balanceOf(msg.sender);
        require( _contractBalance > 0 , "No Token accumulated");
        salesToken.transfer(msg.sender, _contractBalance);

    }

    function getBalance() public view returns(uint256){
        return userBalance[msg.sender];
    }

    function getNftBidStatus(address nftAddress, uint256 tokenID) public view returns(address,uint256){
        return (NFTs[nftAddress][tokenID].bidder,NFTs[nftAddress][tokenID].bid);
    }

}