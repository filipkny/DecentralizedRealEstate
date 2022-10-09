// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RealEstate.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    uint256 internal buyerPk = 0xa11ce;
    uint256 internal sellerPk = 0xb0b;
    uint256 internal inspectorPk = 0xca1;
    uint256 internal appraisorPk = 0xa1c;

    address payable internal buyer = payable(vm.addr(buyerPk));
    address payable internal seller = payable(vm.addr(sellerPk));
    address payable internal inspector = payable(vm.addr(inspectorPk));
    address payable internal appraisor = payable(vm.addr(appraisorPk));

    RealEstate realEstateToken;
    Escrow escrow;
    
    function setUp() public {
        realEstateToken = new RealEstate();
        escrow = new Escrow(appraisor, inspector, address(realEstateToken));

        vm.prank(seller);
        realEstateToken.mint("https://realestate.com/1");

        vm.deal(buyer, 101 ether);
    }


    function testSale() public {
        assertEq(realEstateToken.balanceOf(seller), 1);
        assertEq(realEstateToken.ownerOf(1), seller);

        vm.prank(seller);
        uint256 listingId = escrow.createListing(1);
        
        vm.prank(buyer);
        escrow.depositEscrow{
            value: 1 ether
        }(listingId);

        vm.prank(inspector);
        escrow.approveInspection(listingId);

        vm.prank(appraisor);
        escrow.giveAppraisal(listingId, 100 ether);

        vm.prank(buyer);
        escrow.approveBuy{
            value: 100 ether
        }(listingId);


        assertEq(realEstateToken.ownerOf(1), seller);
        vm.startPrank(seller);
        realEstateToken.setApprovalForAll(address(escrow), true);
        escrow.finalizeSale(listingId);
        

        assertEq(realEstateToken.balanceOf(buyer), 1);
        assertEq(realEstateToken.ownerOf(1), buyer);
    }
}
