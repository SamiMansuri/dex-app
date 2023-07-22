// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20{

    address public tokenAddress;

    constructor(address token) ERC20("ETH TOKEN LP Token", "lpETHTOKEN"){
        require(token!=address(0), "Token address passed is a null address");
        tokenAddress = token;
    }

    function getReserve() public view returns(uint256){
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint256 amountOfToken) public payable returns(uint256){
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReseveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        if(tokenReseveBalance==0){
            token.transferFrom(msg.sender, address(this), amountOfToken);

            lpTokensToMint = ethReserveBalance;

            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;  

        }
    }

    function removeLiquidity(uint256 amountOfLPTokens) public returns(uint256){
        require(amountOfLPTokens>0, "Amount of tokens to remove must be greater than 0");

        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) /lpTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfLPTokens)/ lpTokenTotalSupply;

        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

        return (ethToReturn, tokenToReturn);
    }

    

}