pragma solidity ^0.4.13;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

contract Remitter is Ownable, Destructible {

  struct Remittance {
    uint deadline;
    uint value;
    bytes32 lock; // keccak256(shopAddress, keccak256(password1, password2))
  }

  // Maps an id to a remittance. 
  // The id is the keccak256 hash of the remittance creator, the deadline and the lock.
  mapping(bytes32 => Remittance) public remittances;

  mapping(bytes32 => bool) public lockUsed;

  // Creates a remittance and returns it's id.
  function newRemittance(uint duration, bytes32 lock) payable returns(bytes32 remittanceId) {
    require(msg.value > 0);

    // Check that the log was not used before
    require(!lockUsed[lock]);
    lockUsed[lock] = true;

    uint deadline = block.number + duration;

    // Check for overflow
    assert(deadline > block.number && deadline > duration);
    
    // Return the new remittance's id
    remittanceId = keccak256(msg.sender, deadline, lock);
    
    Remittance storage remittance = remittances[remittanceId];
    require(remittance.lock == 0);
      
    remittance.deadline = deadline;
    remittance.value = msg.value;
    remittance.lock = lock;
  }

  // Creates a lock from the shopAddress and the passwords.
  function createLock(address shopAddress, bytes32 password1, bytes32 password2) constant public returns(bytes32) {
      return keccak256(shopAddress, keccak256(password1, password2));
  }
  
  // This is called by the shop to withdraw funds, by providing the hash of the (tightly packed) passwords.
  function unlockRemittance(bytes32 remittanceId, bytes32 hashedPasswords) {
    Remittance storage remittance = remittances[remittanceId];

    require(remittance.deadline <= block.number);
    require(keccak256(msg.sender, hashedPasswords) == remittance.lock);

    uint value = remittance.value;

    delete remittances[remittanceId];

    msg.sender.transfer(value);
  }

  // This is called by the creator of a remittance to claim back it's funds (after the deadline).
  function claimBack(bytes32 remittanceId) {
    Remittance storage remittance = remittances[remittanceId];
    require(block.number < remittance.deadline);
    require(remittanceId == keccak256(msg.sender, remittance.deadline, remittance.lock));

    uint value = remittance.value;

    delete remittances[remittanceId];

    msg.sender.transfer(value);
  }


}
