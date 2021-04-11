// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.5.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];

        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas, 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract BatchUpdateStateTreeVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[21] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha1 = Pairing.G1Point(uint256(1521146404583750659572698747054957252150580255416380545515204665786584253190),uint256(16239440592833645035397357238610198267583515563354785004455852408906352437752));
        vk.beta2 = Pairing.G2Point([uint256(3210116367012290207258011137528400674817245177333568028277020926215251062363),uint256(3651974151747621340328634751131643626471017072264534841178486375225142090813)], [uint256(2178076429331996984138638772367908291031940617019698883361735428648705244580),uint256(14108757343745497196589116254592631085857829145701685030545238328866902319678)]);
        vk.gamma2 = Pairing.G2Point([uint256(16593792557285504148063927679784370700176510383490650109257750269698035610315),uint256(20341775813561868503059862757426587421010359510304110181754934268510389951023)], [uint256(17722886281839340173029084359751235837423893105809148815484080433441889912160),uint256(2689832663323107534789280980639483790275822383046396123278146460357531618759)]);
        vk.delta2 = Pairing.G2Point([uint256(20243967228062479072268152623925993077376813309298437859989728271087600340918),uint256(13503934955558800401258817895364198895391725323853885726221527908252276052839)], [uint256(4263216684014766893510310225547763645909010259081721336729302700251608340660),uint256(13816978629170749231858960353532609521435888833161149329247844954574158778649)]);
        vk.IC[0] = Pairing.G1Point(uint256(7210746861193047671642458406158631025457709352262648032056738621487662290538),uint256(19673117545304785371207219069389158410955486731874678309381110102471064884522));
        vk.IC[1] = Pairing.G1Point(uint256(21786177247200890146152668273521469045390249226722818875098560523596877098902),uint256(6600425567773582421914965182160769493636949099445880797673031546794697155754));
        vk.IC[2] = Pairing.G1Point(uint256(13440716454298976773522715218373275131968122895685531987424896882221582252361),uint256(11444357131727440661570463150338919993390294735225357211141262538417025860375));
        vk.IC[3] = Pairing.G1Point(uint256(20535177111809643601442846576603422788918321756876820291297654069073054380288),uint256(20208668553499598732235220689320256988636816955157339699149271367572135976930));
        vk.IC[4] = Pairing.G1Point(uint256(16025275060858726770827637175606909213696837466737058111646858732043382833623),uint256(2282286000551260069373528953747254179875072975675291218343488507446807286891));
        vk.IC[5] = Pairing.G1Point(uint256(7055302828975531751550939935638792566592274785884818566311616570200112731019),uint256(17411523918794821452643648553475542598449302917482035540984147673331385913832));
        vk.IC[6] = Pairing.G1Point(uint256(20442510547146862455344447278598087162527800784609546374729078138945796199250),uint256(17136358625585308358258226403280310712165206227969359093545702836612487905414));
        vk.IC[7] = Pairing.G1Point(uint256(5081784841380820705323614405928306160422602267305569569518482998912964996963),uint256(17825377634900204505955552898143643543665416203558770837117280406159471168801));
        vk.IC[8] = Pairing.G1Point(uint256(8066017315584065228838122555133874971228177681351961871269112906011026975205),uint256(4678349249441262372548171520354044836786911175822376111856801909457568161217));
        vk.IC[9] = Pairing.G1Point(uint256(11379006311524262587876610432589397710047798979658778392325060361401548618626),uint256(14122630287571278658539427556837156801175474184059458444508346922959391996071));
        vk.IC[10] = Pairing.G1Point(uint256(18714906073992541108183830191258751267972634520420606402692518424375489193098),uint256(7834090959953240485537618461452545286970826529299291405868070040818531818200));
        vk.IC[11] = Pairing.G1Point(uint256(11934997380514409446747755059936540227874838219793853673977610395351771887431),uint256(16410071907340055128250036195940053581363123579308572333110527896861680499932));
        vk.IC[12] = Pairing.G1Point(uint256(21129781650607486535587774696541832576408935869384553759950766479786295914729),uint256(11713572965368505277123350938154594616714218669856713533962303055880125923358));
        vk.IC[13] = Pairing.G1Point(uint256(18175148884058431816252073254261622235321161025712712091172086563128690380174),uint256(9421998960643832939547244198341408551608851120494530226765307526388253728554));
        vk.IC[14] = Pairing.G1Point(uint256(12771681844362422086171755825349593824444730614960106316623478406731776123014),uint256(3913869673277713490520327420043041959659889278710612548202937409428442168535));
        vk.IC[15] = Pairing.G1Point(uint256(21432219814673879125286348808817896387053780702045521343989332291131506170479),uint256(6812935743088203128048834064563750934175707984586807235762549654031946283194));
        vk.IC[16] = Pairing.G1Point(uint256(21248657558462232738534516497787471885400159017701329210560028284156348814554),uint256(9488290302274267432168472435909272113694547589589670660012152865042681438932));
        vk.IC[17] = Pairing.G1Point(uint256(7270903698864340553419434708112949773036166521801258144772619113029012145552),uint256(17595729871426987532169721566213814957425539908348551591488057560822708201099));
        vk.IC[18] = Pairing.G1Point(uint256(5221649255973428627923393450239763621776067590165846151604076292019845773690),uint256(12321823105696486941896449869683996965932683571860381399355088613525351883095));
        vk.IC[19] = Pairing.G1Point(uint256(9197094564409638003416445490836137675605011101914436443920940612662667729074),uint256(15526748463172027903825322499508806217792095860508339313459802936837920658581));
        vk.IC[20] = Pairing.G1Point(uint256(9230059554650918875049631313064533252246486970344324935032120546478515714952),uint256(9919297955813859803140444297536771767070295323509007741713776752175582496285));

    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        //for (uint256 i = 0; i < input.length; i++) {
        for (uint256 i = 0; i < 20; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alpha1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}
