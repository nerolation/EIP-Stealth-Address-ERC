---
eip: 6467
title: Stealth Meta-Address Registry
description: A registry to map addresses to stealth meta-addresses
author: Matt Solomon (@mds1), Toni Wahrstätter (@nerolation), Ben DiFrancesco (@apbendi), Vitalik Buterin <vitalik.buterin@ethereum.org>
discussions-to: https://ethereum-magicians.org/t/stealth-meta-address-registry/12888
status: Draft
type: Standards Track
category: ERC
created: 2023-01-24
---

## Abstract

This specification defines a standardized way of storing and retrieving an entity's stealth meta-address, by extending [EIP-5564](./eip-5564.md).

## Motivation

The standardization of stealth address generation holds the potential to greatly enhance the privacy capabilities of Ethereum by enabling the recipient of a transfer to remain anonymous when receiving an asset. By introducing a central smart contract for users to store their stealth meta-addresses, EOAs and contracts can programmatically engage in stealth interactions using a variety of stealth address scehemes.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

This contract defines an `ERC5564Registry` that stores the stealth meta-address for entities. These entities may be identified by an address, ENS name, or other identifier. This MUST be a singleton contract, with one instance per chain.

The contract is specified below. A one byte integer is used to identify the stealth address scheme. This integer is used to differentiate between different stealth address schemes. A mapping from the scheme ID to it's specification is maintained at [this](../assets/eip-5564/scheme_ids.md) location.

```solidity
pragma solidity ^0.8.17;

/// @notice Interface for https://eips.ethereum.org/EIPS/eip-1271
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

/// @notice Registry to map an address or other identifier to its stealth meta-address.
contract ERC5564Registry {
    /// @dev Emitted when a registrant updates their stealth meta-address.
    event StealthMetaAddressSet(bytes indexed registrant, uint256 indexed scheme, bytes stealthMetaAddress);

    /// @notice Maps a registrant's identifier to the scheme to the stealth meta-address.
    /// @dev Registrant may be a 160 bit address or other recipient identifier, such as an ENS name.
    /// @dev Scheme is an integer identifier for the stealth address scheme.
    /// @dev MUST return zero if a registrant has not registered keys for the given inputs.
    mapping(bytes => mapping(uint256 => bytes)) public stealthMetaAddressOf;

    /// @notice Sets the caller's stealth meta-address for the given stealth address scheme.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param stealthMetaAddress The stealth meta-address to register.
    function registerKeys(uint256 scheme, bytes memory stealthMetaAddress) external {
        stealthMetaAddressOf[abi.encode(msg.sender)][scheme] = stealthMetaAddress;
    }

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Recipient identifier, such as an ENS name.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param hash      Hash of the data to be signed
    /// @param signature A signature from the `registrant` authorizing the registration.
    /// @param stealthMetaAddress The stealth meta-address to register.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    /// @dev MUST revert if the signature is invalid.
    function registerKeysOnBehalf(
        address registrant,
        uint256 scheme,
        bytes32 hash,
        bytes memory signature,
        bytes memory stealthMetaAddress
    ) external {
        if (_isContract(registrant)) {
            bytes4 result = IERC1271(registrant).isValidSignature(hash, signature);
            require(result == 0x1626ba7e, "INVALID_SIGNATURE");
        } else {
            // If EOA, validate signature
            _recoverSigner(hash, signature);
        }
        stealthMetaAddressOf[abi.encode(registrant)][scheme] = stealthMetaAddress;
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////

    /*
     * @notice Determines if the account is a smart contract
     * @param account   The contract address of the user wallet
     * @return          A boolean indicating if the address is a smart contract
    */
    function _isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // Hash representing an empty account (address with no code)
        // Source https://eips.ethereum.org/EIPS/eip-1052
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            // Get the code hash of the account address
            codehash := extcodehash(account)
        }
        // Check if the code hash is different from the empty account hash and zero
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @notice Recover the signer of hash, assuming it's an EOA account
     * @dev Only for EthSign signatures
     * @param _hash       Hash of message that was signed
     * @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
     * @return signer     Signer of the signature
     */
    function _recoverSigner(bytes32 _hash, bytes memory _signature) private pure returns (address signer) {
        require(_signature.length == 65, "SignatureValidator#recoverSigner: invalid signature length");

        // Variables are not scoped in Solidity.
        uint8 v = uint8(_signature[64]);
        bytes32 r = _readBytes32(_signature, 0);
        bytes32 s = _readBytes32(_signature, 32);

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("SignatureValidator#recoverSigner: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
        }

        // Recover ECDSA signer
        signer = ecrecover(_hash, v, r, s);

        // Prevent signer from being 0x0
        require(signer != address(0x0), "SignatureValidator#recoverSigner: INVALID_SIGNER");
        return signer;
    }

    /**
     * @notice Helper function that reads bytes at memory location and stores in result
     * @dev Used to calculate v and s for signature recovery
     * @param signature    Signature encoded as (bytes32 r, bytes32 s, uint8 v)
     * @param offset       Offset in bytes where the desired bytes32 value starts
     * @return             The extracted bytes32 value
     */
    function _readBytes32(bytes memory signature, uint256 offset) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(signature, add(32, offset)))
        }
        return result;
    }
}
```

Deployment is done using the keyless deployment method commonly known as Nick’s method, {TODO continue describing this and include transaction data, can base it off the format/description used in EIP-1820 and EIP-2470}.

## Rationale

Having a central smart contract for registering stealth meta-addresses has several benefits:

1. It guarantees interoperability with other smart contracts, as they can easily retrieve and utilize the registered stealth meta-addresses. This enables applications such as ENS or Gnosis Safe to use that information and integrate stealth addresses into their services.

2. It ensures that users are not dependent on off-chain sources to retrieve a user's stealth meta-address.

3. Registration of a stealth meta-address in this contract provides a standard way for users to communicate that they're ready to participate in stealth interactions.

4. By deploying the registry as a singleton contract, multiple projects can access the same set of stealth meta-addresses, contributing to improved standardization.

## Backwards Compatibility

This EIP is fully backward compatible.

## Reference Implementation

You can find an implementation of this standard above.

## Security Considerations

TODO

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
