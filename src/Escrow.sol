//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
/**
    Real estate application of a smartcontract.
    Real estate assets are represented as NFTs
    Sellers are able to create listings, buyers are able to accept them.

    There is a master smartcontract that works as an escrow contract and which 
    approves the transfer if the inspector approves it.

    1. Seller mints to create property
    2. Seller creates listing with tokenId pointer
    2.5 Buyer deposits escrow (some fixed amount)
    3. Inspector inspects property and approves it (should get paid from escrow)
    4. Appraiser appraises the property and sets a price (should get paid escrow)
    5.1 Buyer wants to buy property --> approves listing and pays
    5.2 Sellee approves sale -> sale happens
    5.2 Buyer doesn't want to buy property. 



*/
contract Escrow {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    uint256 constant MAX_INT = ~uint256(0);


    uint256 escrowAmount = 1 ether;
    struct Listing {
        uint256 tokenId;
        uint256 price;
        bool inspectorApproved;
        bool buyerApproved;
        address seller;
        address buyer;
    }

    mapping(uint256 => Listing) listings;

    mapping(uint256 => bool) listingNeedsInspectorApproval;
    mapping(uint256 => bool) listingNeedsAppraisal;

    address appraiser;
    address inspector;

    address realEstateTokenContract;

    modifier onlyAppraiser() {
        require (msg.sender == appraiser, "Only appraiser is allowed to make this call");
        _;
    }

    modifier onlyInspector() {
        require (msg.sender == inspector, "Only inspector is allowed to make this call");
        _;
    }

    modifier onlyPropertyOwner(uint256 tokenId) {
        require(IERC721(realEstateTokenContract).ownerOf(tokenId) == msg.sender, "Only the property owner can create a listing");
        _;
    }

    modifier onlyPropertyBuyer(uint256 listingId) {
        require(listings[listingId].buyer == msg.sender, "Only the current potential property buyer can approve the buy");
        _;
    }

    modifier onlyPropertySeller(uint256 listingId) {
        require(listings[listingId].seller == msg.sender, "Only the current potential property seller can finalize the sell");
        _;
    }

    constructor(address newAppraiser, address newInspector, address tokenContract) {
        appraiser = newAppraiser;
        inspector = newInspector;
        realEstateTokenContract = tokenContract;
    }

    function approveInspection(uint256 listingId) external onlyInspector {
        require(listings[listingId].buyer != address(0x0), "Inspection can only be done after a buyer has payed the escrow");
        listings[listingId].inspectorApproved = true;
        listingNeedsInspectorApproval[listingId] = false;
        listingNeedsAppraisal[listingId] = true;
    }

    function giveAppraisal(uint256 listingId, uint256 price) external onlyAppraiser {
        require(listings[listingId].inspectorApproved, "Listing needs to be approved by inspector before appraisal");
        listings[listingId].price = price;
        listingNeedsAppraisal[listingId] = false;
    }

    function approveBuy(uint256 listingId) external payable onlyPropertyBuyer(listingId) {
        require(msg.value == listings[listingId].price);
        listings[listingId].buyerApproved = true;
    }

    function finalizeSale(uint256 listingId) external onlyPropertySeller(listingId) {
        Listing memory listing = listings[listingId];

        require(listing.buyerApproved, "Buyer needs to approve before sale is finalized");

        IERC721(realEstateTokenContract).safeTransferFrom(
            listing.seller,
            listing.buyer,
            listing.tokenId
        );

        delete listings[listingId];
    }

    function createListing(uint256 propertyTokenId) external onlyPropertyOwner(propertyTokenId) returns (uint256) {       
        Listing memory listing = Listing({
            tokenId: propertyTokenId,
            seller: msg.sender,
            inspectorApproved: false,
            price: MAX_INT,
            buyer: address(0x0),
            buyerApproved: false
        });

        _listingIds.increment();
        uint256 newListingId = _listingIds.current();
        listings[newListingId] = listing;

        return newListingId;
    }

    function depositEscrow(uint256 listingId) external payable {
        require(msg.value == escrowAmount, string.concat("Minimum escrow amount is ", Strings.toString(escrowAmount)));
        listings[listingId].buyer = msg.sender;
        listingNeedsInspectorApproval[listingId] = true;
    }

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

}