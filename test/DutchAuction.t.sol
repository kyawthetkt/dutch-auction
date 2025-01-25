// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { TestNFT } from "./mocks/TestNFT.sol";

contract DutchAuctionTest is Test {

    DutchAuction public dutchAuction;
    address private seller;
    address private buyer;
    address private other;
    TestNFT private nft;

    uint256 private constant DURATION = 7 days;
    uint256 private constant STARTING_PRICE = 1e6;
    uint256 private constant DISCOUNT_RATE = 1;
    uint256 private constant NFT_ID = 1;
    uint256 private constant NFT_ID_2 = 2;
    uint256 private constant OTHER_NFT_ID = 3;

    function setUp() public {
        
        dutchAuction = new DutchAuction();
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        other = makeAddr("other");

        // Mint seller 
        nft = new TestNFT();
        nft.mint(seller, NFT_ID);
        nft.mint(seller, NFT_ID_2);
        nft.mint(other, OTHER_NFT_ID);

        vm.label(address(dutchAuction), "DutchAuction");
    }

    modifier autoSellBySeller() {
        vm.startPrank(seller);
        dutchAuction.sell(
            STARTING_PRICE,  
            DISCOUNT_RATE, 
            address(nft),
            NFT_ID, 
            DURATION
        );
        nft.approve(address(dutchAuction), NFT_ID);
        vm.stopPrank();
        _;
    }

    function test_getPrice() public autoSellBySeller {
        /*
        1000000 - (1 * 0)
        1000000 - (1 * 100)
        1000000 - (1 * 200)
        */
        console.log(dutchAuction.getPrice(address(nft), NFT_ID));
        assertEq(dutchAuction.getPrice(address(nft), NFT_ID), STARTING_PRICE);
        skip(100);
        console.log(dutchAuction.getPrice(address(nft), NFT_ID));
        assertEq(dutchAuction.getPrice(address(nft), NFT_ID), STARTING_PRICE - 100 * DISCOUNT_RATE);
        skip(100);
        console.log(dutchAuction.getPrice(address(nft), NFT_ID));
        assertEq(dutchAuction.getPrice(address(nft), NFT_ID), STARTING_PRICE - 200 * DISCOUNT_RATE);
    }

    function test_revert_if_nonowner_try_to_sell() public {
        vm.expectRevert(bytes("DA: you are not owner."));
        vm.startPrank(seller);
        dutchAuction.sell(
            STARTING_PRICE,  
            DISCOUNT_RATE, 
            address(nft),
            OTHER_NFT_ID, 
            DURATION
        );
        vm.stopPrank();
    }
 
    function test_sell_event() public {
        
        vm.expectEmit();
        emit DutchAuction.Sell(seller, address(nft), NFT_ID);
        vm.startPrank(seller);
        dutchAuction.sell(
            STARTING_PRICE,  
            DISCOUNT_RATE, 
            address(nft),
            NFT_ID, 
            DURATION
        );
        nft.approve(address(dutchAuction), NFT_ID);
        vm.stopPrank();
    }

    function test_sell_and_check_approval() public {
        vm.startPrank(seller);
        nft.approve(address(dutchAuction), NFT_ID_2);
        dutchAuction.sell(
            STARTING_PRICE,  
            DISCOUNT_RATE, 
            address(nft),
            NFT_ID_2, 
            DURATION
        );
        vm.stopPrank();
        assert(nft.getApproved(NFT_ID_2) == address(dutchAuction));
    }

    function test_buy_revert_expired() public autoSellBySeller {
        skip(DURATION);
        deal(buyer, 1e18);
        vm.expectRevert(bytes("DA: Auction Expired."));
        vm.prank(buyer);
        dutchAuction.buy{value: STARTING_PRICE}(address(nft), NFT_ID);
    }

    function test_buy_revert_if_insufficient_amount() public autoSellBySeller {
        deal(buyer, 1e18);
        vm.expectRevert(bytes("DA: Invalid Price."));
        vm.prank(buyer);
        dutchAuction.buy{value: 1e2}(address(nft), NFT_ID);
    }

    function test_buy() public autoSellBySeller {

        uint256 price = dutchAuction.getPrice(address(nft), NFT_ID);
        assertGt(price, 0);

        deal(buyer, 1e18);

        uint256 seller_bal0 = seller.balance;
        uint256 buyer_bal0 = buyer.balance;

        vm.startPrank(buyer);
        dutchAuction.buy{value: 1e7}(address(nft), NFT_ID);

        uint256 seller_bal1 = seller.balance;
        uint256 buyer_bal1 = buyer.balance;
        
        assertEq(nft.ownerOf(NFT_ID), buyer);
        assertEq(seller_bal1 - seller_bal0, price);
        assertEq(buyer_bal0 - buyer_bal1, price);
    }

}
