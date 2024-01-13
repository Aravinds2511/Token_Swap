// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "ds-test/test.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {TokenA} from "../src//TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Vm.sol";

contract TokenSwapTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    TokenSwap tokenSwap;
    TokenA tokenA;
    TokenB tokenB;
    address user;

    //setup function
    function setUp() public {
        //deploying contracts
        tokenA = new TokenA(1200 * 1e18);
        tokenB = new TokenB(1200 * 1e18);
        uint256 exchangeRate = 2 * 1e18;
        tokenSwap = new TokenSwap(address(tokenA), address(tokenB), exchangeRate);
        user = address(this);

        //approve TokenSwap contract to spend tokens on behalf of user
        tokenA.approve(address(tokenSwap), type(uint256).max);
        tokenB.approve(address(tokenSwap), type(uint256).max);

        tokenB.transfer(address(tokenSwap), 500 * 1e18);
        tokenA.transfer(address(tokenSwap), 200 * 1e18);

        //transfering some tokens to the user for testing
        tokenA.transfer(user, 700 * 1e18);
        tokenB.transfer(user, 700 * 1e18);
    }

    //testing swapAToB function
    function testSwapAToB() public {
        uint256 userInitialTokenABalance = tokenA.balanceOf(user);
        uint256 userInitialTokenBBalance = tokenB.balanceOf(user);
        uint256 contractInitialTokenBBalance = tokenB.balanceOf(address(tokenSwap));

        uint256 amountToSwap = 100 * 1e18;
        uint256 expectedTokenBAmount = (amountToSwap * tokenSwap.exchangeRate()) / 1e18;

        //performing the swap
        tokenSwap.swapAToB(amountToSwap);

        //assertions after the swap
        assertEq(
            tokenA.balanceOf(user),
            userInitialTokenABalance - amountToSwap,
            "Token A balance should decrease by the swapped amount"
        );
        assertEq(
            tokenB.balanceOf(user),
            userInitialTokenBBalance + expectedTokenBAmount,
            "Token B balance should increase by the expected amount"
        );
        assertEq(
            tokenB.balanceOf(address(tokenSwap)),
            contractInitialTokenBBalance - expectedTokenBAmount,
            "Contract's Token B balance should decrease by the expected amount"
        );
    }

    //testing swapBToA function
    function testSwapBtoA() public {
        uint256 userInitialTokenBBalance = tokenB.balanceOf(user);
        uint256 userInitialTokenABalance = tokenA.balanceOf(user);
        uint256 contractInitialTokenABalance = tokenA.balanceOf(address(tokenSwap));

        uint256 amountToSwap = 100 * 1e18;
        uint256 expectedTokenAAmount = (amountToSwap * 1e18 / tokenSwap.exchangeRate());

        //perform the swap
        tokenSwap.swapBToA(amountToSwap);

        //assertions after the swap
        assertEq(
            tokenB.balanceOf(user),
            userInitialTokenBBalance - amountToSwap,
            "Token B balance should decrease by the swapped amount"
        );
        assertEq(
            tokenA.balanceOf(user),
            userInitialTokenABalance + expectedTokenAAmount,
            "Token A balance should increase by the expected amount"
        );
        assertEq(
            tokenA.balanceOf(address(tokenSwap)),
            contractInitialTokenABalance - expectedTokenAAmount,
            "Contract's Token A balance should decrease by the expected amount"
        );
    }

    //testing for zero amount
    function testFailSwapWithZeroAmount() public {
        uint256 amountToSwap = 0;
        vm.expectRevert("Amount <= zero");
        tokenSwap.swapAToB(amountToSwap);

        vm.expectRevert("Amount <= zero");
        tokenSwap.swapBToA(amountToSwap);
    }

    //testing for minimum amount
    function testSwapAToBMinimumAmount() public {
        uint256 amountToSwap = 1;
        tokenSwap.swapAToB(amountToSwap);
        tokenSwap.swapBToA(amountToSwap);
    }

    //test for swapping more than user balance
    function testSwapMoreThanBalance() public {
        uint256 amountToSwap = tokenA.balanceOf(address(this)) + 1;

        vm.expectRevert("Insufficient Token A");
        tokenSwap.swapAToB(amountToSwap);

        uint256 _amountToSwap = tokenB.balanceOf(address(this)) + 1;

        vm.expectRevert("Insufficient Token B");
        tokenSwap.swapBToA(_amountToSwap);
    }

    //test for swapping for more than contract balance
    function testSwapInsufficientContractBalance() public {
        uint256 amountToSwap = 600 * 1e18;

        vm.expectRevert("Insufficient Token B in contract");
        tokenSwap.swapAToB(amountToSwap);

        uint256 _amountToSwap = 600 * 1e18;

        vm.expectRevert("Insufficient Token A in contract");
        tokenSwap.swapBToA(_amountToSwap);
    }

    //testing ExpectedswapBToAAmount function
    function testExpectedswapBToAAmount() public {
        uint256 tokenBAmount = 100 * 1e18;
        uint256 expectedTokenAAmount = (tokenBAmount * 1e18) / tokenSwap.exchangeRate();

        uint256 actualTokenAAmount = tokenSwap.ExpectedswapBToAAmount(tokenBAmount);
        assertEq(actualTokenAAmount, expectedTokenAAmount, "Expected swap B to A amount is incorrect");
    }

    //testing ExpectedswapAToBAmount function
    function testExpectedswapAToBAmount() public {
        uint256 tokenAAmount = 100 * 1e18;
        uint256 expectedTokenBAmount = (tokenAAmount * tokenSwap.exchangeRate()) / 1e18;

        uint256 actualTokenBAmount = tokenSwap.ExpectedswapAToBAmount(tokenAAmount);
        assertEq(actualTokenBAmount, expectedTokenBAmount, "Expected swap A to B amount is incorrect");
    }
}
