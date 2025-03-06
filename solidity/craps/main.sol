// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title CrapsGame - A decentralized craps game using ChainLink VRF for randomness
/// @notice This contract allows users to play craps with ETH
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CrapsGame is VRFConsumerBase {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    
    // Game state variables
    struct Game {
        uint256 betAmount;
        address player;
        bool isActive;
        uint8 point;
        bool waitingForRoll;
        bool isFirstRoll;
    }
    
    mapping(bytes32 => Game) public games;
    mapping(address => uint256) public playerBalances;
    
    // Events
    event GameStarted(address player, uint256 betAmount);
    event DiceRolled(address player, uint8 die1, uint8 die2, uint8 total);
    event PointSet(address player, uint8 point);
    event GameWon(address player, uint256 winAmount);
    event GameLost(address player);
    
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
    }
    
    // Function to deposit funds
    function deposit() external payable {
        playerBalances[msg.sender] += msg.value;
    }
    
    // Function to withdraw funds
    function withdraw(uint256 _amount) external {
        require(playerBalances[msg.sender] >= _amount, "Insufficient balance");
        playerBalances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
    // Start a new game
    function startGame(uint256 _betAmount) external returns (bytes32) {
        require(playerBalances[msg.sender] >= _betAmount, "Insufficient balance");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        
        playerBalances[msg.sender] -= _betAmount;
        
        bytes32 requestId = requestRandomness(keyHash, fee);
        
        games[requestId] = Game({
            betAmount: _betAmount,
            player: msg.sender,
            isActive: true,
            point: 0,
            waitingForRoll: true,
            isFirstRoll: true
        });
        
        emit GameStarted(msg.sender, _betAmount);
        
        return requestId;
    }
    
    // Continue rolling after point is set
    function rollAgain() external returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        
        bytes32 requestId = requestRandomness(keyHash, fee);
        
        return requestId;
    }
    
    // Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        Game storage game = games[_requestId];
        require(game.isActive, "Game not active");
        require(game.waitingForRoll, "Not waiting for roll");
        
        // Generate two dice rolls between 1-6
        uint8 die1 = uint8((_randomness % 6) + 1);
        uint8 die2 = uint8(((_randomness / 6) % 6) + 1);
        uint8 total = die1 + die2;
        
        emit DiceRolled(game.player, die1, die2, total);
        
        if (game.isFirstRoll) {
            handleFirstRoll(_requestId, total);
        } else {
            handleSubsequentRoll(_requestId, total);
        }
    }
    
    function handleFirstRoll(bytes32 _requestId, uint8 _total) private {
        Game storage game = games[_requestId];
        
        // Natural win (7 or 11)
        if (_total == 7 || _total == 11) {
            uint256 winAmount = game.betAmount * 2;
            playerBalances[game.player] += winAmount;
            emit GameWon(game.player, winAmount);
            game.isActive = false;
        }
        // Craps (2, 3, or 12)
        else if (_total == 2 || _total == 3 || _total == 12) {
            emit GameLost(game.player);
            game.isActive = false;
        }
        // Set point
        else {
            game.point = _total;
            game.isFirstRoll = false;
            game.waitingForRoll = false;
            emit PointSet(game.player, _total);
        }
    }
    
    function handleSubsequentRoll(bytes32 _requestId, uint8 _total) private {
        Game storage game = games[_requestId];
        
        // Win by hitting point
        if (_total == game.point) {
            uint256 winAmount = game.betAmount * 2;
            playerBalances[game.player] += winAmount;
            emit GameWon(game.player, winAmount);
            game.isActive = false;
        }
        // Lose by rolling 7
        else if (_total == 7) {
            emit GameLost(game.player);
            game.isActive = false;
        }
        // Continue rolling
        else {
            game.waitingForRoll = false;
        }
    }
}
