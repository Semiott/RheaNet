pragma solidity ^0.5.2;

import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./IRheaParentToken.sol";
// demo token parent contract


contract SapienParentToken is ISapienParentToken, Ownable {

  event Purpose(address indexed sender, address indexed to, uint256 amount, bytes purpose);

  mapping (address => bool) isBlocked;

  address _childContract;

  constructor (address childContract) public {
    _childContract = childContract;
  }

  modifier onlyChild() {
    require(isChild());
    _;
  }

  function isChild() public view returns (bool) {
    return msg.sender == _childContract;
  }

  function child() public view returns (address) {
    return _childContract;
  }

  function changeChild(address childContract) public onlyOwner {
    _childContract = childContract;
  }

  function beforeTransfer(address sender, address to, uint256 value, bytes calldata purpose) external onlyChild returns(bool) {
    if (isBlocked[sender]){
      return false;
    }

    if (purpose.length > 0) {
      emit Purpose(sender, to, value, purpose);
    }

    return true;
  }

  function updateBlocked(address user, bool permission) public onlyOwner {
    require(user != address(0x0));
    isBlocked[user] = permission;
  }
}
