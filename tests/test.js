const { expect } = require("chai");
const { smock } = require("@defi-wonderland/smock");

describe("TheRarityPlains", function () {

    //I hardcoded some values, please, do not do that at home

    before(async function () {
        this.timeout(60000);
        [deployerSigner] = await ethers.getSigners();

        //Mock rarity
        this.Rarity = await smock.mock('rarity');
        this.rarity = await this.Rarity.deploy();
        //Mock attributes
        this.Rarity_attributes = await smock.mock('rarity_attributes')
        this.rarity_attributes = await this.Rarity_attributes.deploy(this.rarity.address)

        //Deploy
        this.TheRarityPlains = await ethers.getContractFactory("TheRarityPlains");
        this.theRarityPlains = await this.TheRarityPlains.deploy(this.rarity.address,this.rarity_attributes.address);
        await this.theRarityPlains.deployed();

        await this.rarity.summon(5);
        await this.rarity.summon(4);

        await this.rarity.setVariable('level', {
            1: 2
        });

        await this.rarity.setVariable('xp', {
            1: ethers.utils.parseUnits("1500000")
        });
        await this.rarity.approve(this.rarity_attributes.address,1)
        await this.rarity_attributes.point_buy(1,8,8,8,10,20,14)
        await this.rarity_attributes.setVariable('ability_scores', {
            1: (20,20,20,20,20,20)
        })
    });

    it("Should start hunt successfully...", async function () {
        //summoner #0 => level 1, 0 xp
        //summoner #1 => level 2, 15000 xp
        await expect(this.theRarityPlains.startHunt(0)).to.be.reverted;
        await this.theRarityPlains.startHunt(1);
    });

    it("Should kill a creature successfully...", async function () {
        await expect(this.theRarityPlains.killCreature(1)).to.be.reverted;
        await expect(this.theRarityPlains.killCreature(0)).to.be.reverted;

        //Time travel (8 days)
        await network.provider.send("evm_increaseTime", [691200])

        await this.theRarityPlains.killCreature(1);
        let output = await this.theRarityPlains.tokenURI(0)
        let character = await this.rarity_attributes.tokenURI(1)
        let stats = await this.rarity.tokenURI(1)
        let loot = await this.theRarityPlains.loot(0)
        console.log("-name:", loot);

        console.log("Loot URI: " + output)
        console.log("Rarity URI:" + character)
        console.log("Attributes URI:" + stats)

    });


});