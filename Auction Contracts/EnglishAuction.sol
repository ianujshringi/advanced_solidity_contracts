/*
:- English Auction : Seller sets the price at start of the auction and the ending time, When auction ends highest bidder wins. 

:- This contract demonstrate English Auction on an ERC721(nft) Token.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ERC721 Token/IERC721.sol";

contract EnglishAuction {
    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;
    uint32 public endsAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    event Start();
    event Bid(address indexed bidder, uint256 bid);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 highestBid);

    constructor(
        address _nft,
        uint256 _id,
        uint256 _startingBid
    ) {
        nft = IERC721(_nft);
        nftId = _id;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Not Authorized!");
        _;
    }

    function start(uint256 _endAt) external onlySeller {
        require(!started, "Auction already started!");

        started = true;
        endsAt = uint32(block.timestamp + _endAt);
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    function bid() external payable {
        require(started, "Auction not started yet!");
        require(block.timestamp < endsAt, "Auction ended!");
        require(msg.value > highestBid, "More ETH required!");
        if (highestBidder != address(0)) bids[highestBidder] += highestBid;

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 balance = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    function end() external {
        require(started, "Auction not started yet!");
        require(!ended, "Auction ended!");
        require(block.timestamp >= endsAt, "Auction not ended!");

        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
