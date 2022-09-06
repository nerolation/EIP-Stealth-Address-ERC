// SPDX-License-Identifier: CC0-1.0

pragma solidity =0.8.9;

import "./EllipticCurve.sol";

/// @dev Contract to emit Information required by the recipients of private Transfers to determine
///      if they were the recipient of a transfer. Users can derive a key pair from the publishableData
///      part and compare it to the stealthRecipient address. If machting, the respective users can be sure
///      to have the corresponding private key to access the funds. 
/// @notice PubStealthInfoContract MUST be a immutable implementation, shared accross every type of asset that 
///         may be transfered using the stealth address mech
contract PubStealthInfoContract {

    event PrivateTransferInfo(address indexed stealthRecipient, bytes publishableData);

    function emitPrivateTransferInfo(address stealthRecipient, bytes calldata publishableData) external {
        emit PrivateTransferInfo(stealthRecipient, publishableData);
    }
}

contract BasicWallet {

    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    uint256 public PublicKeyX; // e.g. 89565891926547004231252920425935692360644145829622209833684329913297188986597
    uint256 public PublicKeyY; // e.g. 12158399299693830322967808612713398636155367887041628176798871954788371653930


    PubStealthInfoContract public pubStealthInfoContract;

    constructor(uint256 _PublicKeyX, uint256 _PublicKeyY, address _pubStealthInfoContract) {
        PublicKeyX = _PublicKeyX;
        PublicKeyY = _PublicKeyY;
        pubStealthInfoContract = PubStealthInfoContract(_pubStealthInfoContract);
    }


    /// @dev Execute Transfer to stealth address
    /// @param _publishableData Is broadcasted by an immutable implementation of pubStealthInfoContract
    /// TODO: Add ERC20, ERC721 etc. support
    function privateETHTransfer(
        address payable _to, 
        bytes calldata _publishableData
    ) external payable {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        pubStealthInfoContract.emitPrivateTransferInfo(_to, _publishableData);
    }

    /**
        * @dev Generates Stealth Address of the smart contract wallet owner.
        *  The caller executes this function locally to compute a stealth address
        *  that can be accessed by the owner of the smart contract.
        *  Further, function computes a Public Key of the secret that can be published.
        * @notice The public key of the owner must be stored within the contract.
        */
    function generateStealthAddress(uint256 secret) public view returns (uint256, uint256, address){
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
