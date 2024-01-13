// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
GITHUB LINK: https://github.com/Aravinds2511/Token_Swap.git

DESIGN OF THE CONTRACT:

Swap Functions: swapAToB -> Allows users to swap a specified amount of tokenA for tokenB based on the exchange rate.
                swapBToA -> Enables users to swap tokenB for tokenA, again using the exchange rate to determine the amount.

Exchange Rate Management: The exchange rate between tokenA and tokenB is set during contract deployment and 
                          is used to calculate the amount of tokens received in each swap.

Balance Checks: Before any swap, the contract checks if the user has sufficient balance of the token they want 
                to swap and if the contract itself has enough of the token to be swapped in.

Token Transfer: Executes the actual transfer of tokens between the user and the contract. The user’s tokens are 
                transferred to the contract, and the contract sends the corresponding amount of the other token to the user.
*/

contract TokenSwap {
    /////////Errors//////////
    error InsufficientAmount();
    error InsufficientTokenABalance();
    error InsufficientTokenBBalance();
    error InsufficientContractTokenABalance();
    error InsufficientContractTokenBBalance();
    error TokenATransferFailed();
    error TokenBTransferFailed();

    ////////Events///////////

    event TokensSwapped(address indexed user, address indexed fromToken, address indexed toToken, uint256 amount);

    //////////State Variables///////////

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public exchangeRate;

    /////////Constructor//////////

    constructor(address _tokenA, address _tokenB, uint256 _exchangeRate) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        exchangeRate = _exchangeRate; // how much B is A
    }

    ///////////Functions////////////

    function swapAToB(uint256 amount) external {
        if (amount <= 0) revert InsufficientAmount();

        uint256 tokenBAmount = (amount * exchangeRate) / 1e18;

        if (tokenA.balanceOf(msg.sender) < amount) revert InsufficientTokenABalance();
        if (tokenB.balanceOf(address(this)) < tokenBAmount) {
            revert InsufficientContractTokenBBalance();
        }

        if (!tokenA.transferFrom(msg.sender, address(this), amount)) {
            revert TokenATransferFailed();
        }
        if (!tokenB.transfer(msg.sender, tokenBAmount)) revert TokenBTransferFailed();

        emit TokensSwapped(msg.sender, address(tokenA), address(tokenB), amount);
    }

    function swapBToA(uint256 amount) external {
        if (amount <= 0) revert InsufficientAmount();

        uint256 tokenAAmount = (amount * 1e18) / exchangeRate;

        if (tokenB.balanceOf(msg.sender) < amount) revert InsufficientTokenBBalance();
        if (tokenA.balanceOf(address(this)) < tokenAAmount) {
            revert InsufficientContractTokenABalance();
        }

        if (!tokenB.transferFrom(msg.sender, address(this), amount)) {
            revert TokenBTransferFailed();
        }
        if (!tokenA.transfer(msg.sender, tokenAAmount)) revert TokenATransferFailed();

        emit TokensSwapped(msg.sender, address(tokenB), address(tokenA), amount);
    }

    function ExpectedswapBToAAmount(uint256 amount) public view returns (uint256) {
        uint256 tokenAAmount = (amount * 1e18) / exchangeRate;
        return (tokenAAmount);
    }

    function ExpectedswapAToBAmount(uint256 amount) public view returns (uint256) {
        uint256 tokenAAmount = (amount * exchangeRate) / 1e18;
        return (tokenAAmount);
    }
}
