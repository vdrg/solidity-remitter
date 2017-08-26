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
    uint deadline;
    uint value;
    bytes32 lock; // keccak256(receiver, secret)
  }

  event LogNewRemittance(bytes32 indexed remittanceId, address indexed sender, uint deadline, uint value, bytes32 lock);
  event LogRemittanceUnlocked(bytes32 indexed remittanceId, address indexed receiver, bytes32 lock, bytes32 secret);
  event LogRemittanceClaimedBack(bytes32 indexed remittanceId, address indexed sender);

  // Maps an id to a remittance. 
  // The id is the keccak256 hash of the remittance creator, the deadline and the lock.
  mapping(bytes32 => Remittance) public remittances;

  mapping(bytes32 => bool) public lockUsed;

  // Creates a remittance and returns it's id.
  function newRemittance(uint duration, bytes32 lock) payable returns(bytes32 remittanceId) {
    require(msg.value > 0);

    // Check that the lock was not used before
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

    LogNewRemittance(remittanceId, msg.sender, deadline, msg.value, lock);
  }

  // Obtains a lock from the receiver address and the secret.
  function getLock(address receiver, bytes32 secret) constant public returns(bytes32) {
    return keccak256(receiver, secret);
  }

  // This is called by the receiver to withdraw funds, by providing the secret.
  function unlockRemittance(bytes32 remittanceId, bytes32 secret) {
    Remittance storage remittance = remittances[remittanceId];

    require(remittance.deadline <= block.number);
    require(getLock(msg.sender, secret) == remittance.lock);

    uint value = remittance.value;
    bytes32 lock = remittance.lock;

    delete remittances[remittanceId];

    LogRemittanceUnlocked(remittanceId, msg.sender, lock, secret);

    msg.sender.transfer(value);
  }

  // This is called by the creator of a remittance to claim back it's funds (after the deadline).
  function claimBack(bytes32 remittanceId) {
    Remittance storage remittance = remittances[remittanceId];
    require(block.number < remittance.deadline);
    require(remittanceId == keccak256(msg.sender, remittance.deadline, remittance.lock));

    uint value = remittance.value;

    delete remittances[remittanceId];

    LogRemittanceClaimedBack(remittanceId, msg.sender);

    msg.sender.transfer(value);
  }
}
