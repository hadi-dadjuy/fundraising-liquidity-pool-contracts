import { utils, Wallet ,Provider} from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for contracts`)

  // Initialize the wallet.
  const provider = new Provider(hre.userConfig.zkSyncDeploy?.zkSyncNetwork);
  const wallet = new Wallet("YourPk");
 console.time()

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  const dai = await deployer.loadArtifact("ERC20");
  const hdt = await deployer.loadArtifact("ERC20");
  const vault = await deployer.loadArtifact("TokenPool");


  // // Deposit some funds to L2 in order to be able to perform L2 transactions.
  // const depositAmount = ethers.utils.parseEther("0.001");
  // const depositHandle = await deployer.zkWallet.deposit({
  //   to: deployer.zkWallet.address,
  //   token: utils.ETH_ADDRESS,
  //   amount: depositAmount,
  // });
  // await depositHandle.wait();

  // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
  // `greeting` is an argument for contract constructor.
    const daiContract = await deployer.deploy(dai, ["0x636390bE2E1a52abd9cda76830aa1ACC0D26417C", "Test DAI Token", "DAI"]);
    console.log("DAI Contract: ",daiContract.address)
    const hdtContract = await deployer.deploy(hdt, ["0x636390bE2E1a52abd9cda76830aa1ACC0D26417C", "Hadi Dadjuy's Token", "HDT"]);
    console.log("HDT Contract: ",hdtContract.address)

  const vaultContract = await deployer.deploy(vault, [daiContract.address,hdtContract.address, 
  ethers.utils.parseEther("1000000"),ethers.utils.parseEther("200000"),300,28800]);
  console.log("Vault Contract: ", vaultContract.address);


}




// import { utils, Wallet ,Provider} from "zksync-web3";
// import * as ethers from "ethers";
// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// // An example of a deploy script that will deploy and call a simple contract.
// export default async function (hre: HardhatRuntimeEnvironment) {
//   console.log(`Running deploy script for the Greeter contract`)

//   // Initialize the wallet.
//   const provider = new Provider(hre.userConfig.zkSyncDeploy?.zkSyncNetwork);
//   const wallet = new Wallet("0x8a3cce5eb350e52d09a7938ead30689827654afc1ce08e9ffbe395b8575d7762");

//   // Create deployer object and load the artifact of the contract we want to deploy.
//   const deployer = new Deployer(hre, wallet);
//   const dai = await deployer.loadArtifact("ERC20");
//   const hdt = await deployer.loadArtifact("ERC20");

//   // Deposit some funds to L2 in order to be able to perform L2 transactions.
//   const depositAmount = ethers.utils.parseEther("0.001");
//   const depositHandle = await deployer.zkWallet.deposit({
//     to: deployer.zkWallet.address,
//     token: utils.ETH_ADDRESS,
//     amount: depositAmount,
//   });
//   // Wait until the deposit is processed on zkSync
//   await depositHandle.wait();

//   // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
//   // `greeting` is an argument for contract constructor.
//   const daiContract = await deployer.deploy(dai, ["0x636390bE2E1a52abd9cda76830aa1ACC0D26417C", "DAI Token", "DAI"]);
//   const hdtContract = await deployer.deploy(hdt, ["0x636390bE2E1a52abd9cda76830aa1ACC0D26417C", "HDT Token", "HDT"]);


//   await daiContract.transfer("0x90F79bf6EB2c4f870365E785982E1f101E93b906", ethers.utils.parseEther("10000"));
//   await daiContract.transfer("0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", ethers.utils.parseEther("10000"));
//   // Show the contract info.
  
//   console.log(daiContract.address, hdtContract.address);
// }