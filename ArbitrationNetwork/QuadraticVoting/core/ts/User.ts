
import {
    PubKey,
    StateLeaf,
} from 'maci-domainobjs'

import {
    IncrementalQuinTree,
} from 'maci-crypto'

/*
 * Represents a User. In MACI, each user has a public key, a voice credit
 * balance, and the list of votes assigned to each vote option. You can convert
 * a User into a StateLeaf (from maci-domainobjs) but not the other way round.
 * @param _pubKey The user's public key
 * @param _votes The user's votes per vote option
 * @param _voiceCreditBalance The user's voice credit balance
 * @param _voiceCreditBalance The user's voice credit balance
 * @param _nonce The number of valid commands which the user has already
 *               published
 */
class User {
    public pubKey: PubKey
    public votes: BigInt[]
    public voiceCreditBalance: BigInt

    // The this is the current nonce. i.e. a user who has published 0 valid
    // command should have this value at 0, and the first command should
    // have a nonce of 1
    public nonce: BigInt

    constructor(
        _pubKey: PubKey,
        _votes: BigInt[],
        _voiceCreditBalance: BigInt,
        _nonce: BigInt,
    ) {
        this.pubKey = _pubKey
        this.votes = _votes.map(BigInt)
        this.voiceCreditBalance = BigInt(_voiceCreditBalance)
        this.nonce = BigInt(_nonce)
    }

    /*
     * Return a deep copy of this User
     */
    public copy = (): User => {
        const newVotesArr: BigInt[] = []
        for (let i = 0; i < this.votes.length; i++) {
            newVotesArr.push(BigInt(this.votes[i].toString()))
        }

        return new User(
            this.pubKey.copy(),
            newVotesArr,
            BigInt(this.voiceCreditBalance.toString()),
            BigInt(this.nonce.toString()),
        )
    }

    /*
     * Generate a user which should match a blank state leaf
     * @param _voteOptionTreeDepth The depth of the vote option tree
     */
    public static genBlankUser = (
        _voteOptionTreeDepth: number,
    ): User => {
        const votes: BigInt[] = []
        for (let i = 0; i < 5 ** _voteOptionTreeDepth; i ++) {
            votes.push(BigInt(0))
        }

        return new User(
            new PubKey([0, 0].map(BigInt)),
            votes,
            BigInt(0),
            BigInt(0),
        )
    }

    /*
     * Convert this User into a StateLeaf
     * @param _voteOptionTreeDepth The depth of the vote option tree
     */
    public genStateLeaf = (
        _voteOptionTreeDepth: number,
    ): StateLeaf => {
        const voteOptionTree = new IncrementalQuinTree(
            _voteOptionTreeDepth,
            BigInt(0),
        )

        for (const vote of this.votes) {
            voteOptionTree.insert(vote)
        }

        return new StateLeaf(
            this.pubKey,
            voteOptionTree.root,
            this.voiceCreditBalance,
            this.nonce,
        )
    }
}

export { User }
