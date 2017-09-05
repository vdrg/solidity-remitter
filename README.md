# Remitter

This contract lets you lock funds by providing a lock, which is the keccak256 hash of the address that will unlock the funds (the receiver) concatenated with a *secret*.

Then, the receiver has to call `unlockRemittance()` and pass the *secret* as the argument.

## Use case example

Alice wants to send money to Bob, but she has ether and Bob wants to be paid in local currency. Luckily Carol runs an exchange shop that converts ether to local currency.

Alice will create two passwords, one for Carol and the other one for Bob. Then, Alice will lock some funds in the contract, and the secret used to lock them will be the hash of the passwords.

When Carol pays Bob, Bob gives his password to Carol. Then, Carol calls `unlockRemittance(keccak256(password1, password2))` and gets Alice's ether.

# TODO

* Make the owner take a cut of the Ethers
* Tests
