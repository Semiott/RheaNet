
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * @dev Interface of the Fractional NFT standard as defined in the EIP.
 */
interface IFractional {
    /**
     * @dev Emitted when `Fraction` tokens are minted from an NFT lock event
     */
    event Fraction(address nft, address owner, string name, string symbol, uint total);
    event Redeem(uint nftid);

    function fungify(uint[] memory _nftids, uint _total) external;
    function redeem() external payable; 
    function withdrawFee() external;
}
