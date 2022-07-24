/*
:- Dutch Auction : Seller sets the price at start of the auction and the price goes down overtime when buyer think price is low enough he buys and auction ends

:- This contract demonstrate Dutch Auction on an ERC721(nft) Token.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ERC721 Token/IERC721.sol";

contract DutchAuction {
    uint256 private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;

    uint256 public immutable startPrice;
    uint256 public immutable startAt;
    uint256 public immutable endsAt;
    uint256 public immutable discoundRate;

    constructor(
        uint256 _startPrice,
        uint256 _discountRate,
        IERC721 _nft,
        uint256 _id
    ) {
        seller = payable(msg.sender);
        startPrice = _startPrice;
        discoundRate = _discountRate;
        startAt = block.timestamp;
        endsAt = block.timestamp + DURATION;

        // check max discount <= start price
        require(
            _startPrice >= _discountRate * DURATION,
            "Starting price is less than discount"
        );

        nft = IERC721(_nft);
        nftId = _id;
    }

    modifier notEnded() {
        require(block.timestamp < endsAt, "auction ended!");
        _;
    }

    function getPrice() public view returns (uint256) {
        // check for elapsed time
        uint256 timeElapsed = block.timestamp - startAt;
        // calculate disacount
        uint256 discount = discoundRate * timeElapsed;
        // return discounted price
        return startPrice - discount;
    }

    function buy() external payable notEnded {
        uint256 price = getPrice();
        require(msg.value >= price, "Price > Sent ETH !");

        // transfer nft
        nft.transferFrom(seller, msg.sender, nftId);

        // refund excess amount if any
        uint256 refund = msg.value - price;
        if (refund > 0) payable(msg.sender).transfer(refund);

        // delete the auction contract
        selfdestruct(seller);
    }
}
