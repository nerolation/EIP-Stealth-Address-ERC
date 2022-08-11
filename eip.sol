// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "./openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC0001 /* is ERC721, ERC165 */ {

    /// @notice Broadcasts event with a ``Shared Secret``.
    /// @dev Emits event with private transfer information `S`. 
    ///  S is generated by the sender an represents the public key to the private key `s`.
    ///  s is a user-generated secret (MUST NOT be the senders account private key).
    ///  The sender broadcasts S for every transfer. Users can use S to check if they were
    ///  the recipients of a respective transfer.
    /// @param publishableData The public key to the sender's secret
    event PrivateTransfer(bytes publishableData);
}
   

/**
 * @dev Extension of ERC721 to support private ownership using stealth addresses
 *
 * The stealth addresses are generated with a shared secret between the sender and the recipient
 * By converting the shared secret into a address `A` to which the recipient has the private key
 * enables to users to use A as a stealth wallet address. Publishable data is broadcasted after token
 * transfers. Each user can take the publishable data in order to check if one is the recipient of a 
 * transfer. 
 */
abstract contract ERC721Private is ERC165, ERC721 {

    event PrivateTransfer (bytes publishableData);

	constructor(
        string memory name_, 
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    /**
    * @dev See {ERC721-_transfer}. Transfers token with tokenId.
    *  The caller must provide a valid proof of having computed the provided 
    *  stealthAddress and updated a non-empty leaf in the merkle tree
    *  Records the new state_root.
    * @notice the roots, stealthAddressBytes and tokenId are 
    *  public parameter in the arithmetic circuit
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata publishableData
    ) internal virtual { 
        super.safeTransferFrom(from, to, tokenId);
        emit PrivateTransfer(publishableData);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC721) returns (bool) {
        return
            interfaceId == type(ERC0001).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
