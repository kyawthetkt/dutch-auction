// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DutchAuction is ReentrancyGuard {

    event Sell(address indexed seller, address indexed nftAddress, uint256 nftId);
    event Buy(address indexed buyer, address indexed nftAddress, uint256 nftId);

    struct Auction {
        uint256 duration;
        address seller;
        uint256 startingPrice;
        uint256 startsAt;
        uint256 expiresAt;
        uint256 discountRate;
    }
    mapping(address _nft => mapping(uint256 _id => Auction _auction)) public s_auctions;
    
    constructor() {}

    function sell(uint256 _startingPrice, uint256 _discountRate, address _nft, uint256 _id, uint256 _duration) external nonReentrant {

        require(IERC721(_nft).ownerOf(_id) == msg.sender, "DA: you are not owner.");
        // Check if already listed
        require(s_auctions[_nft][_id].seller == address(0), "DA: On Sale");
        require(_startingPrice >= _discountRate * _duration, "DA: Invalid Starting Price.");

        s_auctions[_nft][_id] = Auction({
            duration: _duration,
            seller: msg.sender,
            startingPrice: _startingPrice,
            startsAt: block.timestamp,
            expiresAt: block.timestamp + _duration,
            discountRate: _discountRate
        });
        emit Sell(msg.sender, _nft, _id);
    }

    function buy(address _nft, uint256 _id) external payable nonReentrant {

        Auction storage l_auction = s_auctions[_nft][_id];
        require(l_auction.seller != address(0), "DA: NFT Not On Sale");
        require(block.timestamp < l_auction.expiresAt, "DA: Auction Expired.");

        uint256 price = getPrice(_nft, _id);
        require(msg.value >= price , "DA: Invalid Price.");

        (bool sent_to_seller,) = payable(l_auction.seller).call{value: price}("");
        require(sent_to_seller, "DA: Failed To Send.");

        IERC721(_nft).transferFrom(l_auction.seller, msg.sender, _id);
        
        delete s_auctions[_nft][_id];
        emit Buy(msg.sender, _nft, _id);

        uint256 refund = msg.value - price;
        if ( refund > 0 ) {
            (bool sent,) = msg.sender.call{value: refund}("");
            require(sent, "DA: Faild To Refund");
        }

    }

    function getPrice(address _nft, uint256 _id) public view returns (uint256) {
        Auction storage l_auction = s_auctions[_nft][_id];
        uint256 timeElapsed = block.timestamp - l_auction.startsAt;
        uint256 discount = l_auction.discountRate * timeElapsed;
        return l_auction.startingPrice - discount;
    }

}
