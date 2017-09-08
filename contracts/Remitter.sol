pragma solidity ^0.4.13;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

/*
 * This contract locks an amount of ether. The lock corresponds to keccak256(receiver, secret).
 * To unlock the funds, the receiver must provide the secret.
 * The secret can be anything agreed by the sender and the receiver (for example, the hash of some passwords).
 */
contract Remitter is Ownable, Destructible {

  struct Remittance {
    address sender;
    uint deadline;
    uint value;
  }

  event LogNewRemittance(address indexed sender, bytes32 indexed lock, uint deadline, uint value);
  event LogRemittanceUnlocked(address indexed receiver, bytes32 indexed lock, bytes32 secret);
  event LogRemittanceClaimedBack(address indexed sender, bytes32 indexed lock, uint value);

  // Maps a lock to a remittance. 
  mapping(bytes32 => Remittance) public remittances;

  // Creates a new remittance.
  function newRemittance(uint duration, bytes32 lock)
    payable
    returns(bool success) 
  {
    require(msg.value > 0 && duration > 0);

    Remittance storage remittance = remittances[lock];

    // Check that the lock was not used before
    require(remittance.deadline == 0);

    uint deadline = block.number + duration;

    // Check for overflow
    assert(deadline > block.number && deadline > duration);

    remittance.sender = msg.sender;
    remittance.value = msg.value;
    remittance.deadline = deadline;

    LogNewRemittance(msg.sender, lock, deadline, msg.value);
    return true;
  }

  // Obtains a lock from the receiver address and the secret.
  function getLock(address receiver, bytes32 secret) constant public returns(bytes32) {
    return keccak256(receiver, secret);
  }

  // This is called by the receiver to withdraw funds, by providing the secret.
  function unlockRemittance(bytes32 secret) returns(bool success) {
    bytes32 lock = getLock(msg.sender, secret);
    Remittance storage remittance = remittances[lock];

    require(remittance.value > 0);
    require(remittance.deadline <= block.number);

    uint value = remittance.value;

    LogRemittanceUnlocked(msg.sender, lock, secret);

    remittance.value = 0;
    msg.sender.transfer(value);
    return true;
  }

  // This is called by the creator of a remittance to claim back it's funds (after the deadline).
  function claimBack(bytes32 lock) returns(bool success) {
    Remittance storage remittance = remittances[lock];

    require(block.number < remittance.deadline);
    require(remittance.sender == msg.sender);

    uint value = remittance.value;

    LogRemittanceClaimedBack(msg.sender, lock, value);

    remittance.value = 0;
    msg.sender.transfer(value);
    return true;
  }
}
