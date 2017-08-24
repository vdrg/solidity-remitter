var Remittances = artifacts.require("./Remittances.sol");

module.exports = function(deployer) {
  deployer.deploy(Remittances);
};
