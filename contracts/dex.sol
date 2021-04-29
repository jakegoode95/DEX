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
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns (Order[] memory){
        return orderBook[ticker][uint(side)];

        }

    function createLimitOrder(Side side,bytes32 ticker,uint amount,uint price) public {
         if(side == Side.BUY){
        require(balances[msg.sender]["ETH"] >= amount.mul(price),"ETH balance is not sufficient");
        } 
        else if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount);
        }

        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(
            Order(nextOrderId,msg.sender, side, ticker, amount, price, 0)
         );

        //Bubble sort
        
         uint i = orders.length > 0 ? orders.length - 1 : 0; //defines the start, if array is empty it equals 0, shortened if statement
        if(side == Side.BUY){
            while(i > 0){
                if(orders[i - 1].price > orders[i].price) {
                    break;
                    // if everything is in order e.g [10,9,8] breaks loop
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
                // this swaps the orders so that they are in the correct order
            }
        }
        // in this array smallest price needs to be to the left[9,5,2]
        // could put these together to remove extra code
        else if(side == Side.SELL){
            while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                    break;   
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        nextOrderId++;

    }
       function createMarketOrder(Side side,bytes32 ticker,uint amount) public{
           if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "insufficient balance");
           }
           uint orderBookSide;
           if(side == Side.BUY){
               orderBookSide = 1;
           }
           else{
               orderBookSide = 0;
           }

           Order[] storage orders = orderBook[ticker][orderBookSide];

           uint totalFilled = 0;

           for(uint256 i = 0; i < orders.length && totalFilled < amount; i++){
              
              
            uint leftToFill = amount.sub(totalFilled); //amount - totalFilled
            uint availableToFill = orders[i].amount.sub(orders[i].filled); //order.amount - order.filled
            uint filled = 0;

            if(availableToFill > leftToFill){
                filled = leftToFill;// fill entire market order 
            }
            else{ 
                filled = availableToFill;// fill as much as is available in market order[i]
            }

            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);

            //execute the trade & shift balances between buyer/seller
            if(side == Side.BUY){
                require(balances[msg.sender]["ETH"] >= cost);
            //msg.sender is the buyer
            //transfer ETH from Buyer to Seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
            //transfer tokens from seller to buyer
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else if(side == Side.SELL){
            //msg.sender is the seller
            //transfer ETH from Buyer to Seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
            
            //transfer tokens from seller to buyer
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);

            }

           }
             // loop through the order book and remove 100% filled orders
             // very costly on gas using this while loop, as the array grows so will the gas consumption

            while(orders.length > 0 && orders[0].filled == orders[0].amount){
            // remove the top element in the order array by overwriting every element 
            // with the next element in the order list
            for (uint256 i = 0; i < orders.length -1; i++){
                orders[i] = orders [i + 1];

            }
            orders.pop();
         }
                   
     }          
     
 }
     





