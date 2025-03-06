# web3-casino-games

Python implementations of some basic casino games, rewritten as solidity smart contracts.

## Games

### Craps

#### Key Differences from the Python Version

1. **Randomness**: Uses Chainlink VRF (Verifiable Random Function) for secure randomness on the blockchain
2. **Game State**: Tracks game state in a struct rather than through function execution flow
3. **Betting System**: Added a betting system with deposits and withdrawals
4. **Asynchronous Nature**: Unlike Python, the dice rolling is asynchronous due to blockchain limitations
5. **Events**: Uses events to notify players and frontends about game progress

To implement this in a real project, you would need:

1. A Chainlink VRF subscription for randomness
2. LINK tokens to pay for the randomness requests
3. A frontend to interact with this contract

Note that this implementation is simplified and would need additional security considerations for a production environment.
