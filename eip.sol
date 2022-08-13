// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../contracts/EllipticCurve.sol";


contract Wallet {

  uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public constant AA = 0;
  uint256 public constant BB = 7;
  uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  uint256 public PublicKeyX = 89565891926547004231252920425935692360644145829622209833684329913297188986597;
  uint256 public PublicKeyY = 12158399299693830322967808612713398636155367887041628176798871954788371653930;

   /**
    * @dev Generates Stealth Address of the smart contract wallet owner.
    *  The caller executes this function locally to compute a stealth address
    *  that can be accessed by the owner of the smart contract.
    * @notice The public key of the owner must be stored within the contract
    */
  function generateStealthAddress(uint256 secret) public view returns (address){
    //  s*P
    (uint256 Qx,uint256 Qy) = EllipticCurve.ecMul(secret, PublicKeyX, PublicKeyY, AA, PP);
    // hash(sharedSecret)
    bytes32 hQ = keccak256(abi.encodePacked(Qx, Qy));
    // hash to public key
    (Qx, Qy) = EllipticCurve.ecMul(uint(hQ), GX, GY, AA, PP);
    // generate address
    (Qx, Qy) = EllipticCurve.ecAdd(PublicKeyX, PublicKeyY, Qx, Qy, AA, PP);
    // return stealth address
    return address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
  }
}
