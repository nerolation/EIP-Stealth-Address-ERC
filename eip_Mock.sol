// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "./eip.sol";

contract ERC71PrivateMock is ERC721Private {
    constructor(
        string memory name, 
        string memory symbol
    ) ERC721Private(name, symbol) {}

    function mintToken(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function burnToken(uint256 tokenId) public {
        _burn(tokenId);
    }

     function transferToken(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    function transferTokenPrivate(address from, address to, uint256 tokenId, bytes calldata publishableData) public {
        _transfer(from, to, tokenId, publishableData);
    }
}
