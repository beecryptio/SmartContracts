pragma solidity ^0.4.11;
contract DEx {
    
    struct Escrow {
        uint256 expiryTime; //timestamp
        address sender; //who escrows amount
        address receiver; //to whom amount is escrowed
        uint256 amount;
    }
    
    mapping(bytes32 => Escrow) escrows; //map that holds all the escrows
    address creator;
    
    function DEx() {
        creator = msg.sender;
    }
    
    /* create a escrow by sending amount to a receiver address with an expiry block timestamp of future.
    * _hash: SHA256 hash value of secret
    * _expiry: timestamp of a future date
    * _receiver: address to which amount is escrowed
    */
    function addEscrow(bytes32 _hash, uint256 _expiry, address _receiver) payable returns (bool z) {
        if(_expiry > now && address(escrows[_hash].sender) == 0 && msg.value > 0) {
            escrows[_hash].sender = msg.sender;
            escrows[_hash].amount = msg.value;
            escrows[_hash].expiryTime = _expiry;
            escrows[_hash].receiver = _receiver;
            return true;
        }
        else {
            return false;
        }
    }
    
    /* claim escrow by revealing secret by the receiver, or in case of sender claim after escrow expiry time.
    * _secret: secret in bytes, length random
    */
    
    function claimEscrow(bytes _secret) returns (bool z){
        var hash = sha256(_secret);
        var amount = escrows[hash].amount;
        if(escrows[hash].receiver == msg.sender) {
            escrows[hash].amount = 0;
            msg.sender.transfer(amount);
            return true;
        }
        else if(escrows[hash].sender == msg.sender && now > escrows[hash].expiryTime) {
            escrows[hash].amount = 0;
            msg.sender.transfer(amount);
            return true;
        }
        else {
            return false;
        }
    }
    
    /* returns escrow data for a given hash
    * _hash: hash value for which data is returned
    */
    function escrow(bytes32 _hash) constant returns (uint256 amount, address sender, address receiver, uint256 expiry){
        var escrowData = escrows[_hash];
        return (escrowData.amount, escrowData.sender, escrowData.receiver, escrowData.expiryTime);
    }
    
    /*
    * sweep for a given hash after 3 years after expiry in case the value is not claimed back either by sender or receiver
    */
    function sweep(bytes32 _hash) {
        if(msg.sender == creator) {
            if(now > (escrows[_hash].expiryTime + 3 years)) {
                var amt = escrows[_hash].amount;
                escrows[_hash].amount = 0;
                msg.sender.transfer(amt);
            }
        }
    }
}
