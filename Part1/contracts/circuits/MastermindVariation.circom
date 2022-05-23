pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// this circuit implements the number mastermind variation of the original mastermind game. All numbers greater than 0 and less than 10 are valid inputs.
template MastermindVariation() {

    // signals for the guesses made by the code breaker
    signal input guessA;
    signal input guessB;
    signal input guessC;
    signal input guessD;

    // nwhite signals are given when the code breaker's guess exist in the solution, but not in the right position
    signal input nWhite;
    // nBlack signals are given when the code breaker's guess exists and is in the right position
    signal input nBlack;
    // clue signal is a sum of the code maker's solution, given to help the code breaker.
    signal input clue;

    // signals for the code maker's code
    signal input solnA;
    signal input solnB;
    signal input solnC;
    signal input solnD;
    signal input salt;

    // signals for the public hash of the code maker's code
    signal input pubSolnHash;

    // intermediate signal for calculation the sum of the code maker's solution.
    signal solnSum;

    // output signal
    signal output solnHash;

    // an array of the guesses and solutions
    var guess[4] = [guessA, guessB, guessC, guessD];
    var soln[4] = [solnA, solnB, solnC, solnD];

    var j = 0;
    var k = 0;
    component greaterThan[8];
    component lessThan[8];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all greater than 0 but less than 10
    for (j=0; j<4; j++) {

        // greater than 0
        greaterThan[j] = GreaterThan(4);
        greaterThan[j].in[0] <== guess[j];
        greaterThan[j].in[1] <== 0;
        greaterThan[j].out === 1;

        greaterThan[j+4] = GreaterThan(4);
        greaterThan[j+4].in[0] <== soln[j];
        greaterThan[j+4].in[1] <== 0;
        greaterThan[j+4].out === 1;

        // less than 10
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 10;
        lessThan[j].out === 1;

        lessThan[j+4] = LessThan(4);
        lessThan[j+4].in[0] <== soln[j];
        lessThan[j+4].in[1] <== 10;
        lessThan[j+4].out === 1;

        for (k=j+1; k<4; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }

    }

    // count black and whites
    var white = 0;
    var black = 0;
    component equalCounts[16];

    for (j=0; j<4; j++) {
        for (k=0; k<4; k++) {
            equalCounts[4*j+k] = IsEqual();
            equalCounts[4*j+k].in[0] <== soln[j];
            equalCounts[4*j+k].in[1] <== guess[k];
            white += equalCounts[4*j+k].out;
            if (j == k) {
                black += equalCounts[4*j+k].out;
                white -= equalCounts[4*j+k].out;
            }
        }
    } 

    // Create a constraint around the number of blacks
    component equalBlack = IsEqual();
    equalBlack.in[0] <== nBlack;
    equalBlack.in[1] <== black;
    equalBlack.out === 1;
    
    // Create a constraint around the number of whites
    component equalWhite = IsEqual();
    equalWhite.in[0] <== nWhite;
    equalWhite.in[1] <== white;
    equalWhite.out === 1;

    // create a constraint around the given clue
    solnSum <== solnA + solnB + solnC + solnD;
    
    component correctClue = IsEqual();
    correctClue.in[0] <== clue;
    correctClue.in[1] <== solnSum;
    correctClue.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== salt;
    poseidon.inputs[1] <== solnA;
    poseidon.inputs[2] <== solnB;
    poseidon.inputs[3] <== solnC;
    poseidon.inputs[4] <== solnD;

    solnHash <== poseidon.out;
    pubSolnHash === solnHash;

}

component main {public [guessA, guessB, guessC, guessD, nWhite, nBlack, pubSolnHash]} = MastermindVariation();

/* INPUT = {
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
} */