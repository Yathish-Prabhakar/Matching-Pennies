// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/* This contract implements MatchingPennies
*  Two players are allowed to play the game using the contract at once
*  The first player starts the game by sending 0.5 ETH to the contract
*  along with their hashed choice
*  The second player sends their hashed choice along with 0.5 ETH to the contract
*  In reveal phase, the two players send their choices with salt and they are verified
*  by the contract
*  The contract decides the winner and declares it
*  The winner can pull their reward of 1 ETH from the contract
*/

contract MatchingPennies{
    
    address public player1;
    address public player2;
    address public winner;
    egameStatus gameStatus;
    choices playerOneChoice;
    choices playerTwoChoice;
    bytes32 playerOneHash;
    bytes32 playerTwoHash;
    
    enum egameStatus{
        NOT_STARTED, COMMIT_IN_PROGRESS, REVEAL_PHASE, COMPLETED
    }
    
    enum choices{
        ZERO, ONE, NONE
    }
    
    event gameEvents(string message);
    
    function getGameStatus() external view returns(string memory gamestatus){
        if(gameStatus==egameStatus.NOT_STARTED){
            return "NOT STARTED";
        }
        if(gameStatus==egameStatus.COMMIT_IN_PROGRESS){
            return "COMMIT IN PROGRESS";
        }
        if(gameStatus==egameStatus.REVEAL_PHASE){
            return "REVEAL PHASE";
        }
        if(gameStatus==egameStatus.COMPLETED){
            return "COMPLETED";
        }
    }
    
    function makeYourChoice(bytes32 hashedChoice) external payable{
        require(gameStatus==egameStatus.NOT_STARTED || gameStatus==egameStatus.COMMIT_IN_PROGRESS,"Game in progress");
        require(msg.value==500000000 gwei, "Invalid bet amount");
        
        if(player1==address(0x0)){
            player1 = msg.sender;
            playerOneHash = hashedChoice;
            playerOneChoice=choices.NONE;
            gameStatus = egameStatus.COMMIT_IN_PROGRESS;    
            emit gameEvents("Player one has started the game and commited their choice");
        }
        else if(player1!=address(0x0)){
            require(msg.sender!=player1, "Can't play against yourself");
            player2 = msg.sender;
            playerTwoHash = hashedChoice;
            playerTwoChoice=choices.NONE;
            gameStatus = egameStatus.REVEAL_PHASE;
            emit gameEvents("Player two has participated in the game and commited their choice");
        }
    }
    
    function revealChoice(choices choice, string calldata salt) external payable{
        require(gameStatus==egameStatus.REVEAL_PHASE, "Game not started");
        require(choice==choices.ONE || choice==choices.ZERO, "Invalid choice");
        
        if(msg.sender==player1 && playerOneChoice==choices.NONE){
            checkHashedChoice(choice, salt, player1);
        }
        else if(msg.sender==player2 && playerTwoChoice==choices.NONE){
            checkHashedChoice(choice, salt, player2);
        }
    }
    
    function checkHashedChoice(choices choice, string calldata salt, address player) internal{
        if(player==player1){
            if(keccak256(abi.encode(choice,salt))!=playerOneHash){
                cancelGame();
            }
            else{
                playerOneChoice=choice;
            }
        }
        else if(player==player2){
            if(keccak256(abi.encode(choice,salt))!=playerTwoHash){
                cancelGame();
            }
            else{
                playerTwoChoice=choice;
            }
        }
        if(playerTwoChoice!=choices.NONE && playerOneChoice!=choices.NONE){
            emit gameEvents("Reveal phase is completed");
            revealWinner();
        }
    }
    
    function cancelGame() private{
        emit gameEvents("Game cancelled - Invalid hash");
        
        player1 = address(0x0);
        player2 = address(0x0);
        winner = address(0x0);
        gameStatus = egameStatus.NOT_STARTED;
        playerOneChoice=choices.NONE;
        playerTwoChoice=choices.NONE;
        playerOneHash="";
        playerTwoHash="";
    }
    
    function revealWinner() private{
        if(playerOneChoice==playerTwoChoice){
            winner = player1;
        }
        else{
            winner = player2;
        }
        
        emit gameEvents("The winner is declared");
        
        gameStatus = egameStatus.COMPLETED;
        playerOneChoice=choices.NONE;
        playerTwoChoice=choices.NONE;
    }
    
    function claimReward() external{
        require(gameStatus==egameStatus.COMPLETED,"Game not over yet");
        require(msg.sender==winner,"You are not the winner");
        require(address(this).balance>=1 ether,"Insufficient reward amount");
        
        player1 = address(0x0);
        player2 = address(0x0);
        winner = address(0x0);
        gameStatus = egameStatus.NOT_STARTED;
        playerOneHash="";
        playerTwoHash="";
        
        emit gameEvents("The winner has been rewarded");
        //send reward to the winner
        (bool result, ) = payable(msg.sender).call{value:1 ether}("");
        require(result==true,"Reward sending failed");
    }
    
}