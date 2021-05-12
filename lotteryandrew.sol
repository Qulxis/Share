//Lottery Example: By Andrew Xavier
//Rules: 
// Compile with version 4.26
//1. Each person can only enter once, or must withdraw and then re-enter to change their amount.
//2. The selection must be done by the manager.
//3. If you win, you can withdraw your winnings using the same withdraw command as in 1.

pragma solidity ^0.4.17;

contract Lottery{
    mapping(address => bool) public managers;
    mapping(address => playerEntry) public players;
    address[] private playerList;
    address public lastWinner;
    struct playerEntry {
        uint index;
        uint amount;
    }
   
    
    modifier onlyManagers() {
        // Ensure the participant awarding the ether is the manager
        require(managers[msg.sender]);
        _;
    }
    
    modifier notEntered() {
        // only allow players to enter once
        require(players[msg.sender].index == 0);
        require(players[msg.sender].amount == 0);
        _;
    }
    
    modifier hasEntered() {
        // only allow players to enter once
        require(players[msg.sender].amount != 0);
        _;
    }
    
    //Student: Not sure if we want to use the index or amount to track if a player has entered but even then, using not sure how we actually check if someone has entered or not this way.
    //I feel like doing a "if msg.sender is in playerList, allow" is viable, but I don't know how to implement that either

    constructor() public{
        managers[msg.sender] = true;
    }
    
    //Student: Doesn't this make any person a manager by default?
    
    function addManager(address newManager) public onlyManagers {
        // add a new manager
        managers[newManager] = true;
    }
    
    function removeManager(address manager) public onlyManagers {
        // remove a manager
        managers[manager] = false;
    }
    
    function enter() public notEntered payable{
        // enforce a minimum bet
        require(msg.value > 0.001 ether);
        
        // add sender address to the list
        uint newIndex = playerList.length; // The index of this new person 
        playerList.push(msg.sender);
        
        // create new playerEntry
        
        players[msg.sender] = playerEntry(newIndex , msg.value);
    }
    
    function withdraw() public hasEntered {
        // save amount to withdraw into a variable
        uint withdrawAmt = players[msg.sender].amount;
        
        // first remove from the array
        removeFromLottery(players[msg.sender].index);
        
        //Student: Remove what from the array?? I'm guessing here
        
        // remove from mapping
        delete players[msg.sender];
        
        // finally, send withdrawn funds to account (good practice to do last)
        msg.sender.transfer(withdrawAmt);
    }

    function pickWinner() public onlyManagers {
        // specify the winner
        lastWinner = playerList[ random() % playerList.length ];

        // setup for another lottery
        resetLottery();
        

        // transfer all money from lottery contract to the player
        uint contractAmnt = address(this).balance;
        players[lastWinner].amount = contractAmnt;
    }

    function getPlayers() public view returns (address[]) {
        // Return list of players
        return playerList;
    }
    
    function resetLottery() private {
        // clear player mapping
        //
        for (uint i  = 0; i < playerList.length; i++) { //update for 
            delete players[playerList[i]];
        }
        
        
        //Not sure if that is what it wants
   
        
        // reinitialize the playerList
        playerList = new address[](0);
    }
    
    // iterate through the playerList and remove the withdrawn player
    function removeFromLottery(uint indx) private {
        // check that index is not too big
        
        //Student: I changed the variable that's passed in to "indx" so it's not confused with "index" for a player in "players"
        if (indx >= playerList.length) return;

        // move entries above index down by one
        // 1. Get the index of the address from sender, but indx should be that already and is passed in when this is called
        // 2. Start from this index in array and iterate up to the second to last entry in the array. (Note that the array starts at 0, thus the length is 1 larger than the largest index. 
        // The less than accounts for this in the for statement, but we need a -1 so it stops before it gets to the last one)

        for (uint i  = indx; i < playerList.length - 1; i++) { 
            playerList[i] = playerList[i+1]; // 3.set value in each valid entry in array to be the one above
            players[playerList[i+1]].index = i; // 4.use value "the one above" to access map, and set the index mapped to this address to the correct index (i)
        }

            
        
        // actually remove the entry
        delete playerList[playerList.length-1]; //sets last value to 0x000000...
        playerList.length--; //removes that end piece

    }
    
    // helper function to find the winner
    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, playerList)));
    }
}
