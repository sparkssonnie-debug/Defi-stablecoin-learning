//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//Imports
import {Test, console2} from "forge-std/src/Test.sol";
import {StdInvariant} from "forge-std/src/StdInvariant.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    DeployDSC public deployer;
    DSCEngine public engine;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;
    address weth;
    address wbtc;
    Handler public handler;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (,, weth, wbtc) = config.getActiveConfig();
        handler = new Handler(address(engine), address(dsc));
        targetContract(address(handler));
    }

    function invariant_protocalMustHaveMoreCollateralThanTotalDSCMinted() public view {
        uint256 totalDscMinted = dsc.totalSupply();
        uint256 totalEthCollateral = IERC20(weth).balanceOf(address(engine));
        uint256 totalBtcCollateral = IERC20(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getUsdValue(weth, totalEthCollateral);
        uint256 wbtcValue = engine.getUsdValue(wbtc, totalBtcCollateral);

        console2.log("totalDscMinted", totalDscMinted);
        console2.log("wethValue", wethValue);
        console2.log("wbtcValue", wbtcValue);
        console2.log("timesMintIsCalled", handler.timesMintIsCalled());

        assert(wethValue + wbtcValue >= totalDscMinted);
    }

    function invariant_gettersShouldNotRevert() public view {
        engine.getCollateralTokens();
        engine.getCollateralBalanceOfUser(msg.sender, weth);
        engine.getCollateralBalanceOfUser(msg.sender, wbtc);
        engine.getAccountInformation(msg.sender);
    }
}
