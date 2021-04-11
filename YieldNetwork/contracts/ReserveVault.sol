pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

contract ReserveVault is ERC20, ERC20Burnable {
    using SafeMath for uint256;
    address private _underlyingAsset;
    uint256 private _tokenId;
    uint256 private _cap;

    constructor(
        address nft,
        uint256 numTokens,
        string memory tokenName,
        string memory symbol,
        address issuer,
        uint256 tokenIdd
    ) ERC20(tokenName, symbol) {
        _underlyingAsset = nft;
        _tokenId = tokenIdd;
        _cap = numTokens;
        _mint(issuer, numTokens);
        emit Transfer(address(0x0), issuer, numTokens);
    }

    function underlyingAsset() public view returns (address) {
        return _underlyingAsset;
    }

    function tokenId() public view returns (uint256) {
        return _tokenId;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // When minting tokens
            require(
                totalSupply().add(amount) <= cap(),
                "ERC20Capped: cap exceeded"
            );
        }
    }
}
