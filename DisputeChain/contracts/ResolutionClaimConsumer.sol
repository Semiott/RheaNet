pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract ResolutionClaimConsumer is ChainlinkClient {
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    uint256 public windSpeed;
    
    /**
     * Network: Kovan
     * Oracle: 
     *      Name:           Alpha Chain - Kovan
     *      Listing URL:    https://market.link/nodes/ef076e87-49f4-486b-9878-c4806781c7a0?start=1614168653&end=1614773453
     *      Address:        0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b
     * Job: 
     *      Name:           OpenWeather Data
     *      Listing URL:    https://market.link/jobs/e10388e6-1a8a-4ff5-bad6-dd930049a65f
     *      ID:             235f8b1eeb364efc83c26d0bef2d0c01
     *                      19f99ba9c9ea41a18f402b031ccc9584 - temp
     *      Fee:            0.1 LINK
     */
     /**
     * Network: Mumbai
     * Oracle: 
     *      Name:           - Mumbai
     *      Listing URL:    
     *      Address:        0xA470258c3a66673F7723127e42747C1B80Df59b5
     * Job: 
     *      Name:           OpenWeather Data
     *      Listing URL:    https://market.link/jobs/e10388e6-1a8a-4ff5-bad6-dd930049a65f
     *      ID:             6da41688d2e04a04bb34ffefde1a3bd6
     *      Fee:            0.0001 LINK 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     *      Link:           0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     *                      0x70d1F773A9f81C852087B77F6Ae6d3032B02D2AB
     */
    constructor() public {
        setChainlinkToken(0x70d1F773A9f81C852087B77F6Ae6d3032B02D2AB);
        oracle = 0xA470258c3a66673F7723127e42747C1B80Df59b5;
        jobId = "48aa30e2a5aa4944ba136618a674ef50";
        fee = 0;//.0001 * 10 ** 18;
    }
    
    /**
     * Initial request
     */
    function requestWindSpeedByZip(string memory _zip) public {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillWindSpeed.selector);
        req.add("zip", _zip);

        sendChainlinkRequestTo(oracle, req, fee);
    }
    
    /**
     * Callback function
     */
    function fulfillWindSpeed(bytes32 _requestId, uint256 _windSpeed) public recordChainlinkFulfillment(_requestId) {
        windSpeed = _windSpeed;
    }
}
