# Matching-Pennies-using-ethereum

 This contract implements MatchingPennies  
 Two players are allowed to play the game using the contract at once  
 The first player starts the game by sending 0.5 ETH to the contract along with their hashed choice  
 The second player sends their hashed choice along with 0.5 ETH to the contract  
 In reveal phase, the two players send their choices with salt and they are verified by the contract  
 The contract decides the winner and declares it  
 The winner can pull their reward of 1 ETH from the contract
