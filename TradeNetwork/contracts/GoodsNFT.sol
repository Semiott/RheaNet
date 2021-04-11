pragma solidity 0.6.6;

import "../external/contracts/token/ERC721/ERC721.sol";
import "../external/contracts//contracts/utils/Counters.sol";
import "../external/contracts//contracts/access/Ownable.sol";


contract GoodsNFT is ERC721, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor(string memory name, string memory symbol) 
    public 
    ERC721(name, symbol)   
  {
    _setBaseURI("https://ipfs.io/ipfs/");
  }

  function mintItem(address to, string memory tokenURI)
      public
      returns (uint256)
  {
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(to, id);
      _setTokenURI(id, tokenURI);

      return id;
  }
}
