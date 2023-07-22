// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address token) ERC20("ETH TOKEN LP Token", "lpETHTOKEN") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function addLiquidity(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        if (tokenReserveBalance == 0) {
            token.transferFrom(msg.sender, address(this), amountOfToken);

            lpTokensToMint = ethReserveBalance;

            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;
        }
        // If the reserve is not empty, calculate the amount of LP Tokens to be minted
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance) /
            ethReservePriorToFunctionCall;

        require(
            amountOfToken >= minTokenAmountRequired,
            "Insufficient amount of tokens provided"
        );

        // Transfer the token from the user to the exchange
        token.transferFrom(msg.sender, address(this), minTokenAmountRequired);

        // Calculate the amount of LP tokens to be minted
        lpTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        // Mint LP tokens to the user
        _mint(msg.sender, lpTokensToMint);

        return lpTokensToMint;
    }

    function removeLiquidity(
        uint256 amountOfLPTokens
    ) public returns (uint256, uint256) {
        require(
            amountOfLPTokens > 0,
            "Amount of tokens to remove must be greater than 0"
        );

        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) /
            lpTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfLPTokens) /
            lpTokenTotalSupply;

        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

        return (ethToReturn, tokenToReturn);
    }

    // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserve must be greater than 0"
        );

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function ethToTokenSwap(uint256 minTokensToReceive) public payable {
        uint256 tokenReseveBalance = getReserve();
        uint256 tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            address(this).balance - msg.value,
            tokenReseveBalance
        );
        require(
            tokensToReceive >= minTokensToReceive,
            "Tokens received are less than minimum tokens expected"
        );
        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }

    function tokenToEthSwap(
        uint256 tokensToSwap,
        uint256 minEthToRecieve
    ) public {
        uint256 tokenReseveBalance = getReserve();
        uint256 ethToRecieve = getOutputAmountFromSwap(
            tokensToSwap,
            tokenReseveBalance,
            address(this).balance
        );

        require(
            ethToRecieve >= minEthToRecieve,
            "ETH received is less than minimum ETH expected"
        );

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokensToSwap
        );

        payable(msg.sender).transfer(ethToRecieve);
    }
}
