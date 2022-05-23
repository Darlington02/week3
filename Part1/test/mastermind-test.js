//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const path = require("path");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe("Mastermind Variation", function () {
    this.timeout(100000000);

    it("Compiles Circuit", async () => {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();

        const INPUT = {
            "salt": "4",
            "solnA": "8",
            "solnB": "3",
            "solnC": "2",
            "solnD": "9",
            "guessA": "1",
            "guessB": "2",
            "guessC": "8",
            "guessD": "9",
            "nWhite": "2",
            "nBlack": "1",
            "pubSolnHash": "2460595271854442012564476155685594234333094812144680612084983640310898160611",
            "clue": "22"
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        console.log(witness);

        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(2460595271854442012564476155685594234333094812144680612084983640310898160611)))
    });
});