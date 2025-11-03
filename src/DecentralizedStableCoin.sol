//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//Imports
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin
 * @author Sonnie Sparks
 * Collateral: Exogenous (ETH,BTC)
 * Minting: Algorithmic
 * Relative stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine.(Just the ERC20 implementation)
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    //Errors
    error DecentralizedStableCoin_MustBeMoreThanZero();
    error DecentralizedStableCoin_BurnAmountExceedsBalance();
    error DecentralizedStableCoin_NotZeroAddress();

    //Functions
    constructor() Ownable(msg.sender) ERC20("DecentralizedStableCoin", "DSC") {}

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin_NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin_BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }
}
