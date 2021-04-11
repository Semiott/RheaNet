// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract ResolutionReserverConsumer is ChainlinkClient {

    event RequestAPIGet(address user, bytes32 indexed requestId);
    event APIGetIssued(bytes32 indexed requestId, uint256 maticPrice);

    uint256 public price;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Network: Kovan
     * Oracle: Chainlink - 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Job ID: Chainlink - 29fa9aa13bf1468788b7cc4a500a45b8
     * Fee: 0.1 LINK
     */
    // constructor(address _oracle, bytes32 _jobId) public {
    constructor(address _linkToken, address _oracle, bytes32 _jobId) public {
        // setPublicChainlinkToken(); // no need to use Pointer here, just set the token address with setChainlinkToken
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = _jobId;
        fee = 1 * 10 ** 18; // 1 LINK
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestPriceData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on

        // TODO: https://api.coingecko.com/api/v3/simple/price?ids=matic-network&vs_currencies=usd

        request.add("get", "https://api.coingecko.com/api/v3/simple/price?ids=matic-network&vs_currencies=usd");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {
        //   "matic-network": {
        //      "usd":0.01722094
        //   }
        // }
        request.add("path", "matic-network.usd");
        
        // Multiply the result by 100000000 to remove decimals
        int timesAmount = 10**8;
        request.addInt("times", timesAmount);

        // Sends the request
        requestId = sendChainlinkRequestTo(oracle, request, fee);
        emit RequestAPIGet(msg.sender, requestId);

    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        price = _price;
        emit APIGetIssued(_requestId, _price);
    }
}
