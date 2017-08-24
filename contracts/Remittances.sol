pragma solidity ^0.4.13;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

contract Remittances is Ownable, Destructible {

  struct Remittance {
    uint deadline;
    uint value;
    bytes32 hashedPassword1;
    bytes32 hashedPassword2;
  }

  mapping(address => mapping(address => Remittance)) public remittances;


  function newRemittance(address receiver, uint duration, bytes32 hashedPassword1, bytes32 hashedPassword2) payable {
    uint deadline = block.number + duration;

    // Check for overflow
    assert(deadline > block.number && deadline > duration);

    Remittance memory remittance = Remittance(
      deadline,
      msg.value,
      hashedPassword1,
      hashedPassword2
    );

    remittances[msg.sender][receiver] = remittance;
  }

  function withdraw(address sender, address receiver, bytes32 password1, bytes32 password2) {
    Remittance storage remittance = remittances[sender][receiver];

    require(
      keccak256(password1) == remittance.hashedPassword1 &&
      keccak256(password2) == remittance.hashedPassword2
    );

    uint value = remittance.value;

    delete remittances[sender][receiver];

    msg.sender.transfer(value);
  }

  function claimBack(address receiver) {
    Remittance storage remittance = remittances[msg.sender][receiver];
    require(block.number < remittance.deadline);

    uint value = remittance.value;

    delete remittances[msg.sender][receiver];

    msg.sender.transfer(value);
  }

}
