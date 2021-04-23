//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";


contract Dex is Wallet {

    using SafeMath for uint256;

    enum Side {
        BUY, // 0
        SELL // 1
    }
// order that will be in the order book
    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
    }

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns (Order[] memory){
        return orderBook[ticker][uint(side)];

        }
    function depositEth() payable external{
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(msg.value);   
        
        }

    function createLimitOrder(Side side,bytes32 ticker,uint amount,uint price) public {
         if (side == Side.BUY){
        require(balances[msg.sender]["ETH"] >= amount.mul(price),"ETH balance is not sufficient");
        }
    }

     
}




