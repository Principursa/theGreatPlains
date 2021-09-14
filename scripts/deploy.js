async function main() {
    //Compile
    await hre.run("clean");
    await hre.run("compile");

    //Deploy
    const TheRarityPlains = await ethers.getContractFactory("TheRarityPlains");
    const theRarityPlains = await TheRarityPlains.deploy("0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb");
    await theRarityPlains.deployed();
    console.log("Deployed to:", theRarityPlains.address);

    //Verify
    await hre.run("verify:verify", {
        address: theRarityPlains.address,
        constructorArguments: ["0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb"],
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });