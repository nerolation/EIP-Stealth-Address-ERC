// SPDX-License-Identifier: CC0-1.0

pragma solidity =0.8.9;

import "./EllipticCurve.sol";


contract EIP5564 {

    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @notice Mapping of addresses to  public key coordinates
    /// @dev Is used by other wallets to generate stealth addresses
    ///  on behalf of the recipient.
    ///  The first mapping maps addresses the key 0 and 1, containing
    ///  the X and the Y coordinate of the public key.
    mapping(address => mapping(uint256 => uint256)) keys;

    /// @dev Event emitted when a user transfers assets to a stealth address
    event Annoucement(
        address indexed stealthRecipient, 
        bytes announcement
    );

    /// @dev Event emitted when a user updates their registered stealth keys
    event StealthKeyChanged(
        address indexed registrant,
        uint256 pubKeyPrefix,
        uint256 pubKey
    );


    constructor() {}


    /**
    * @notice Returns the stealth key associated with an address.
    * @param _registrant The address of the registrant.
    * @param _PubKeyX The X public key coordinate of the registrant.
    * @param _PubKeyY The Y public key coordinate of the registrant.
    */
    function registerKey(
        address _registrant,
        uint256 _PubKeyX,
        uint256 _PubKeyY
    ) external {
        keys[_registrant][0] = _PubKeyX;
        keys[_registrant][1] = _PubKeyY;
        emit StealthKeyChanged(_registrant, _PubKeyX, _PubKeyY);
    }


    /**
    * @notice Returns the stealth key associated with an address.
    * @param _registrant The address whose keys to lookup.
    * @return PubKeyX X public key coordinate of public key
    * @return PubKeyY Y public key coordinate of public key
    */
    function stealthKeys(address _registrant)
        public
        view
        returns (
        uint256 PubKeyX,
        uint256 PubKeyY
        )
    {
        return (keys[_registrant][0], keys[_registrant][1]);
    }

    /**
    * @notice Emits event with information on the stealth-address transfer.
    * @param stealthRecipient The address of the recipient of the transfer.
    * @param publishableData Information required by the recipient.
    */
    function emitAnnoucement(address stealthRecipient, bytes calldata publishableData) external {
        emit Annoucement(stealthRecipient, publishableData);
    }


    /**
    * @dev Generates Stealth Address on behalve of a registered user.
    *  The caller executes this function locally to compute a stealth address
    *  that can be accessed by recipient.
    *  Further, function computes a Public Key of the secret that can be published.
    * @notice The public key of the owner must be stored within the contract.
    */
    function generateStealthAddress(uint256 secret, address target) public view returns (uint256, uint256, address){
        // Retrieve public key coordinates of target
        (uint256 PublicKeyX, uint256 PublicKeyY)  = stealthKeys(target);
        //  s*G = S
        (uint256 pubDataX,uint256 pubDataY) = EllipticCurve.ecMul(secret, GX, GY, AA, PP);
        //  s*P = q
        (uint256 Qx,uint256 Qy) = EllipticCurve.ecMul(secret, PublicKeyX, PublicKeyY, AA, PP);
        // hash(sharedSecret)
        bytes32 hQ = keccak256(abi.encodePacked(Qx, Qy));
        // hash value to public key
        (Qx, Qy) = EllipticCurve.ecMul(uint(hQ), GX, GY, AA, PP);
        // derive new public key
        (Qx, Qy) = EllipticCurve.ecAdd(PublicKeyX, PublicKeyY, Qx, Qy, AA, PP);
        // generate stealth address
        address stealthAddress = address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
        // return public key coordinates and stealthAddress
        return (pubDataX, pubDataY, stealthAddress);
    }
}
