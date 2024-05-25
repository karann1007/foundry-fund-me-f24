//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

import {Test , console} from '../../lib/forge-std/src/Test.sol';
import {FundMe} from '../../src/FundMe.sol';
import {DeployFundMe} from '../../script/DeployFundMe.s.sol';

contract FundMeTest is Test{
    FundMe fundMe;
    address USER = makeAddr('user');
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;


    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER,STARTING_BALANCE);
    }

    function testMinimumUsd() view public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testSenderIsOwner() view public {
        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public {
        assertEq(fundMe.getVersion(),4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // expects a code revert next line
        fundMe.fund();       // send 0 ETH which will revert 
    }

    function testFundUpdatesDataStructure() public {
        vm.prank(USER);            // prank() -> next transaction will be by the USER
        fundMe.fund{value:SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);

    }

    function testAddsFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(USER,funder);

    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();            // ----------> Here anvil/ Other chainlink that deployed fundMe contract will be the owner and not the USER
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACT
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // ASSERT

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMebalance = address(fundMe).balance;

        assertEq(endingFundMebalance,0);
        assertEq(startingFundMeBalance + startingOwnerBalance , endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded{
        // ARRANGE
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // uint256 constant GAS_PRICE = 1; 

        for(uint160 i = startingFunderIndex;i<numberOfFunders;i++) {
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACT 
        // uint256 startGas = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 endGas = gasleft();
        // uint256 gasUsed = (startGas - endGas) * tx.gasprice;
        // console.log(gasUsed);
        // ASSERT

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerbalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerbalance , startingOwnerBalance + startingFundMeBalance);
    }
}

// forge test --match-test testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
// --fork-url simulates an actual node