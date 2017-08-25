var Remitter = artifacts.require("./Remitter.sol");

module.exports = function(deployer) {
  deployer.deploy(Remitter);
};
