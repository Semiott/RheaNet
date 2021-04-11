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

contract QuadVoteTallyVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[11] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha1 = Pairing.G1Point(uint256(18527995650986764041104306667851585929730095119586362797208849248692283520483),uint256(20627204732789916467381917404107453729094489608479102629708344896197132552401));
        vk.beta2 = Pairing.G2Point([uint256(14944571007124739678418099846827034939023524222486211574439954553060226796844),uint256(11275794785108899364808410840391053388912249262268515246436626107805409628060)], [uint256(19974776447113659028611034756620263533666267116603645525750573691156128801313),uint256(19803478617724902832055785214666154300768953076713177897838342076768467494756)]);
        vk.gamma2 = Pairing.G2Point([uint256(11792268276345807699367309637845185669421239661005857402596168489712256781510),uint256(16733485737588922930033990262392426154969883960178878129990670637284902039839)], [uint256(12914061469695898916247638779963444154071427803667383727946032803437190239149),uint256(20140570907465347006119217433328959851807660156379895646738427119443499431593)]);
        vk.delta2 = Pairing.G2Point([uint256(11507453331407609573070611907726805063117488526735126019981671482376837250654),uint256(9307212230806320616864383085221031969458805276664490084842027259640556035143)], [uint256(19146959242741024176982082571295770777877696274351420856100531576229336051773),uint256(2505563686498159257374556321970752991862754542662490153789448709226259966184)]);
        vk.IC[0] = Pairing.G1Point(uint256(9478742242475741821616047136270253498634196227823409181533430776242983552462),uint256(7861052567331656103979851995566874011329036302803220317767556861445845377188));
        vk.IC[1] = Pairing.G1Point(uint256(12945584642585927012768146678839256743057838921065772643110362940409964780478),uint256(19098357443046034776695863440691109479421293865957381827937653494406883420584));
        vk.IC[2] = Pairing.G1Point(uint256(13614908163642538117702212402962490846876412920678203515922436856218922713244),uint256(15306815514516403438691861752744616178454542387402082475081533739869833911303));
        vk.IC[3] = Pairing.G1Point(uint256(4888492973271436977328652173315446315000548376333823973406084230096556185622),uint256(7711978339701285254702210716247682743556385224073780395588339471599206488975));
        vk.IC[4] = Pairing.G1Point(uint256(20263846675002349232303001789271517341743255646587511448068940318267569563037),uint256(8359531582034179250489103329971690077861432993900156865643558089875016204305));
        vk.IC[5] = Pairing.G1Point(uint256(21013847355647766448398078695993501389912264766462288114452526400314105324573),uint256(20234329585494313497597171505899385741779311280905038436884859397387487878394));
        vk.IC[6] = Pairing.G1Point(uint256(19764399127605337242664666306440488007380352626299435887786690894822078123760),uint256(21289102925729168312331353296947490075432149308383908581362352586746631567885));
        vk.IC[7] = Pairing.G1Point(uint256(16245300278602356508594673233594578476441301830854118481993901079001794756437),uint256(10389379174080377468114295369153964260561905237301366684067318144911675591763));
        vk.IC[8] = Pairing.G1Point(uint256(18713025582936097033611368625998898210833269177273707981914801215808481274724),uint256(15826073294133344627268681492550163508246044315988792051835890292575583734386));
        vk.IC[9] = Pairing.G1Point(uint256(1228382728376099674056212637429339271411974409781397596562305175242478244358),uint256(13249461611689090000478531266068731086178664645638496206888283373408177247760));
        vk.IC[10] = Pairing.G1Point(uint256(9609401637464690707583578516963761566673660401993183665792660358894503387563),uint256(14282843533912229976261033940509960872984116748111541452959504631789281337251));

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
        for (uint256 i = 0; i < 10; i++) {
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
