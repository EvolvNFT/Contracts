async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Factory = await ethers.getContractFactory("Factory");
    const factory = await Factory.deploy("0x979942EC8eE350f7b59862f823842C1341dACc47", "0x979942EC8eE350f7b59862f823842C1341dACc47");
  
    console.log("Factory address:", factory.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });