// Copyright © 2017 Beecrypt IO Private Limited. 
// This file is part of Migretor.

// Migretor is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Migretor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Migretor.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.13;
contract DEx {
    
    struct Escrow {
        uint256 expiryTime; //timestamp
        address sender; //who escrows amount
        address receiver; //to whom amount is escrowed
        uint256 amount;
        bytes secret;
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
    
    /* claim escrow by revealing secret by the receiver
    * _secret: secret in bytes, length random
    */
    
    function claimEscrow(bytes _secret) returns (bool z) {
        var hash = sha256(_secret);
        var amount = escrows[hash].amount;
        if(escrows[hash].receiver == msg.sender) {
            escrows[hash].secret = _secret;
            escrows[hash].amount = 0;
            msg.sender.transfer(amount);
            return true;
        }
        else {
            return false;
        }
    }
		
    /* withdraw escrow in case of sender claim after escrow expiry time.
    * _hash: hash in bytes
    */		
		function withdrawEscrow(bytes32 _hash) returns (bool z) {
        if(escrows[_hash].sender == msg.sender && now > escrows[_hash].expiryTime) {
            var amount = escrows[_hash].amount;
						escrows[_hash].amount = 0;
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
    function escrow(bytes32 _hash) constant returns (uint256 amount, address sender, address receiver, uint256 expiry, bytes secret){
        var escrowData = escrows[_hash];
        return (escrowData.amount, escrowData.sender, escrowData.receiver, escrowData.expiryTime, escrowData.secret);
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
