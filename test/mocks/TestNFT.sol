// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor () ERC721("TestNFT", "TNFT") {}

    function mint(address _to, uint256 _tokenId) public {
        _mint(_to, _tokenId);
    }
}