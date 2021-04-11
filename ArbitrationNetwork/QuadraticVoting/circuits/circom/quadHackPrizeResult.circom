include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "./trees/incrementalQuinTree.circom";
include "./trees/incrementalMerkleTree.circom";
include "./hasherPoseidon.circom";
include "./trees/calculateTotal.circom";
include "./trees/checkRoot.circom";
include "./quadVoteTally.circom"

template QuadHackPrizeResultGenerator() {

    signal private input ParticipantPublicKey;
    signal private input OrganizerPublicKey;
    signal input OrganizerReviewInput;
    signal input AttendeeInput;
    signal input ProjectIdentifier;
    
    signal output PrizeSponsorPublishedResults;
    signal output PrizeSponsorPublishedPending;

    signal aux;

    aux <== (OrganizerReviewInput-AttendeeInput)*ProjectIdentifier;   
    PrizeSponsorPublishedResults <==  aux + OrganizerReviewInput;
    PrizeSponsorPublishedPending <== -aux + AttendeeInput;
}

component main = QuadHackPrizeResultGenerator();


template ResultCommitmentVerifier(voteOptionTreeDepth) {
    var numVoteOptions = 5 ** voteOptionTreeDepth;

    signal input currentResultsSalt;
    signal input currentResultsCommitment;
    signal input currentResults[numVoteOptions];

    signal input newResultsSalt;
    signal input newResults[numVoteOptions];
    signal output newResultsCommitment;

    // Salt and hash the results up to the current batch
    component currentResultsTree = QuinCheckRoot(voteOptionTreeDepth);
    component newResultsTree = QuinCheckRoot(voteOptionTreeDepth);
    for (var i = 0; i < numVoteOptions; i++) {
        newResultsTree.leaves[i] <== newResults[i];
        currentResultsTree.leaves[i] <== currentResults[i];
    }

    component currentResultsCommitmentHasher = HashLeftRight();
    currentResultsCommitmentHasher.left <== currentResultsTree.root;
    currentResultsCommitmentHasher.right <== currentResultsSalt;

    // Also salt and hash the result of the current batch
    component newResultsCommitmentHasher = HashLeftRight();
    newResultsCommitmentHasher.left <== newResultsTree.root;
    newResultsCommitmentHasher.right <== newResultsSalt;

    // Check if the salted hash of the results up to the current batch is valid
    currentResultsCommitment === currentResultsCommitmentHasher.hash;

    newResultsCommitment <== newResultsCommitmentHasher.hash;
}
