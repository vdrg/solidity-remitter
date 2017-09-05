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
    bool initialized;
  }

  event LogNewRemittance(address indexed sender, uint deadline, uint value, bytes32 lock);
  event LogRemittanceUnlocked(address indexed receiver, bytes32 lock, bytes32 secret);
  event LogRemittanceClaimedBack(address indexed sender, uint value);

  // Maps a lock to a remittance. 
  mapping(bytes32 => Remittance) public remittances;

  // Creates a remittance and returns it's id.
  function newRemittance(uint duration, bytes32 lock) payable {
    require(msg.value > 0 && duration > 0);

    Remittance storage remittance = remittances[lock];

    // Check that the lock was not used before
    require(!remittance.initialized);

    uint deadline = block.number + duration;

    // Check for overflow
    assert(deadline > block.number && deadline > duration);

    remittance.sender = msg.sender;
    remittance.value = msg.value;
    remittance.deadline = deadline;
    remittance.initialized = true;

    LogNewRemittance(msg.sender, deadline, msg.value, lock);
  }

  // Obtains a lock from the receiver address and the secret.
  function getLock(address receiver, bytes32 secret) constant public returns(bytes32) {
    return keccak256(receiver, secret);
  }

  // This is called by the receiver to withdraw funds, by providing the secret.
  function unlockRemittance(bytes32 secret) {
    bytes32 lock = getLock(msg.sender, secret);
    Remittance storage remittance = remittances[lock];

    require(remittance.initialized == true);
    require(remittance.value > 0);
    require(remittance.deadline <= block.number);

    uint value = remittance.value;

    LogRemittanceUnlocked(msg.sender, lock, secret);

    remittance.value = 0;
    msg.sender.transfer(value);
  }

  // This is called by the creator of a remittance to claim back it's funds (after the deadline).
  function claimBack(bytes32 lock) {
    Remittance storage remittance = remittances[lock];
    require(block.number < remittance.deadline);
    require(remittance.sender == msg.sender);

    uint value = remittance.value;

    LogRemittanceClaimedBack(msg.sender, value);

    remittance.value = 0;
    msg.sender.transfer(value);
  }
}
