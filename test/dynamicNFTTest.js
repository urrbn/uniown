const { expect } = require("chai");

describe("UniOwnPass", function () {
    let UniOwnPass, uniOwnPass, owner, addr1, addr2;

    beforeEach(async () => {
        UniOwnPass = await ethers.getContractFactory("UniOwnPass");
        [owner, addr1, addr2, _] = await ethers.getSigners();
        uniOwnPass = await UniOwnPass.deploy();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await uniOwnPass.owner()).to.equal(owner.address);
        });

        it("Should assign the total dividends", async function () {
            expect(await uniOwnPass.totalDividends()).to.equal(5);
        });

        it("Should assign the total spent", async function () {
            expect(await uniOwnPass.totalSpent()).to.equal(6);
        });
    });

    describe("Transactions", function () {
        it("Should mint tokens", async function () {
            await uniOwnPass.connect(addr1).safeMint(1);
            expect(await uniOwnPass.getCounter()).to.equal(1);
        });

        it("Should return correct tokenURI after minting", async function () {
            await uniOwnPass.connect(addr1).safeMint(10);

            const uri = await uniOwnPass.tokenURI(1);
            console.log(uri, 'uri')
            // Remove the prefix
            let base64Data = uri.replace("data:application/json;base64,", "");
            
            // Decode the Base64 string
            let decodedData = Buffer.from(base64Data, 'base64').toString('utf8');
            
            // Parse the JSON
            let json = JSON.parse(decodedData);
            
            console.log(json);
      
        });

        it("Should fail if trying to access a token URI that doesn't exist", async function () {
            await expect(uniOwnPass.tokenURI(1)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
        });
    });
});