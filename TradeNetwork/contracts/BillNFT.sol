pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract BillNFT is ERC1155, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;



  constructor (string memory uri_) 
     public 
     ERC1155 (uri_) 
  {
     _setURI(uri_);
  }

  function _mintItem( uint256 amount) public returns (uint256) 
  
  {
     
     _tokenIds.increment();
      uint256 id = _tokenIds.current();
      _mint(msg.sender, id,amount,"");
      return id;
  }

}
   
        
    
