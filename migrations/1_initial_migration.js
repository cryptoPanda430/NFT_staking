const config = require("../config/params.json");
const web3 = require("web3");
const ChipRace = artifacts.require("ChipRaceContract");
const MutantChipRace = artifacts.require("MutantChipRaceContract");


module.exports = async function (deployer) {

  //For Test Net
  //await deployer.deploy(ChipRace, "0xD20086Ff85bc773f54d16Abce2e5bA0dD616B395", "0x8070c987d80B1363710BF53998C9078ebD75A05B", "0xe9852a19b7E15993d99a51099eb3f8DAC4f51997", "0x6F5C750714ED738c26870caB5F135307B8922315");
  
  //For Main Net
  // await deployer.deploy(ChipRace, "0x3a7951ff955d4e0b6cbbe54de8593606e5e0fa08", "0x1B967351e96Bc52E7f4c28EB97406bfa7eB8c8b2", "0xFBb4F2f342c6DaaB63Ab85b0226716C4D1e26F36", "0xE11E38fB9F9f4227f8F1B31143A34771D5BD2717");

  //Mutant
  await deployer.deploy(MutantChipRace, "0x4d548AEdf1B1647464033864A2E306dE40354859", "0xe9852a19b7E15993d99a51099eb3f8DAC4f51997", "0xF5A7D73d52a1994ff3581C5fC3f8f2A69DD37925");
  
  const chipRaceInstance = await MutantChipRace.deployed();
  console.log("MutantChipRace deployed at:", chipRaceInstance.address);
  try { 
    for (let i = 0; i < config.chiprace_param.mutantCarType.length; i ++) {
      const car = config.chiprace_param.carType[i];
      await chipRaceInstance.setCarType(car.uri, car.type);
    }
    for(let i = 0; i < config.chiprace_param.targetScore.length; i++) {
      const scoreData = config.chiprace_param.targetScore[i];
      await chipRaceInstance.setTargetScoreOf(scoreData.level, scoreData.score);
    }
    for (let i = 0 ; i < config.chiprace_param.minableAmount.length; i++) {
      const levelData = config.chiprace_param.minableAmount[i];
      for(let j = 0; j < levelData.amount.length; j++) {
        await chipRaceInstance.setMinableAmount(levelData.carType, j, web3.utils.toWei(levelData.amount[j].toString()));
      }
    }
    for (let i = 0; i < config.chiprace_param.upgradeAmount.length; i++) {
      const upgradeLevel = config.chiprace_param.upgradeAmount[i];
      for(let j = 0; j < upgradeLevel.amount.length; j++) {
        await chipRaceInstance.setUpgradeAmount(upgradeLevel.carType, j + 1, web3.utils.toWei(upgradeLevel.amount[j].toString()));
      }
    }          
    

    console.log("MutantChipRace deployed at:", chipRaceInstance.address);
  } catch(error) {
    console.log(error);
  }
 
 };
// const config = require("../config/Mutant.json");
// const Toxic = artifacts.require("ToxicNFT");
// const Mutant = artifacts.require("MutantNFT");
// module.exports = async function (deployer) {
//   await deployer.deploy(Toxic,"0xFBb4F2f342c6DaaB63Ab85b0226716C4D1e26F36");
//   const toxicInstance = await Toxic.deployed();
//   console.log("Toxic  deployed at:", toxicInstance.address)

//   await deployer.deploy(Mutant,"0x3a7951ff955d4e0b6cbbe54de8593606e5e0fa08", "0x1B967351e96Bc52E7f4c28EB97406bfa7eB8c8b2", toxicInstance.address);
//   const mutantInstance = await Mutant.deployed();
//   console.log("Mutant  deployed at:", mutantInstance.address)

//   try {
//     for(let i = 0; i < config.mutant_param.mutantPairs.length; i++) {
//       const pair = config.mutant_param.mutantPairs[i];
//       await mutantInstance.setPairs(pair.origin, pair.mutant);
//     }
//   } catch(error) {
//     console.log(error);
//   }
// };


