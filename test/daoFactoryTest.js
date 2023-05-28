const { expect } = require("chai");

describe("UniOwnfactory", function() {
    let UniOwnDAO;
    let uniOwnDAO;
    let UniOwnfactory;
    let uniOwnfactory;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function() {
        UniOwnDAO = await ethers.getContractFactory("UniOwnDAO");
        uniOwnDAO = await UniOwnDAO.deploy();
        await uniOwnDAO.deployed();

        UniOwnfactory = await ethers.getContractFactory("UniOwnfactory");
        uniOwnfactory = await UniOwnfactory.deploy(uniOwnDAO.address);
        await uniOwnfactory.deployed();

        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    });

    describe("Deployment", function() {
        it("Should set the right UniOwnMaster", async function() {
            expect(await uniOwnfactory.uniOwnMaster()).to.equal(uniOwnDAO.address);
        });
    });

    describe("DAO creation", function() {
        it("Should create a DAO", async function() {
            await uniOwnfactory.connect(owner).deployUniOwnDAO(
                "Test DAO",
                "TDAO",
                false,
                [owner.address, addr2.address],
                [50, 50]
            );

            expect(await uniOwnDAO.name()).to.equal("Test DAO");
            expect(await uniOwnDAO.symbol()).to.equal("TDAO");
            expect(await uniOwnDAO.paused()).to.equal(false);
            expect(await uniOwnDAO.voters(0)).to.equal(addr1.address);
            expect(await uniOwnDAO.voters(1)).to.equal(addr2.address);
            expect(await uniOwnDAO.shares(addr1.address)).to.equal(50);
            expect(await uniOwnDAO.shares(addr2.address)).to.equal(50);
        });
    });
});