// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "./eip.sol";

contract ERC71PrivateMock is ERC721Private {
    constructor(
        string memory name, 
        string memory symbol
    ) ERC721Private(name, symbol) {}

    function privateTransferFrom(address from, address to, uint256 tokenId, bytes calldata publishableData) public {
        _transfer(from, to, tokenId, publishableData);
    }
}
