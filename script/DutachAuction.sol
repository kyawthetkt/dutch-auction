// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DutchAuction} from "../src/DutchAuction.sol";

contract DutchAuctionScript is Script {
    DutchAuction public dutchAuction;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        dutchAuction = new DutchAuction();
        vm.stopBroadcast();
    }
}
