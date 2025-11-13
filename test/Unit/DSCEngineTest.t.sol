//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//Imports
import {Test} from "forge-std/src/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    //State Variables
    DeployDSC public deployer;
    DSCEngine public engine;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;
    address wbtc;

    address USER = makeAddr("user");
    uint256 COLLATERAL_AMOUNT = 10 ether;
    uint256 STARTING_ERC20_BALANCE = 100 ether;

    //Functions
    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (wethUsdPriceFeed,, weth,) = config.getActiveConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    //Constructor Tests
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertIfTokenAddressesAndPriceFeedAddressesAmountsDontMatch() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wethUsdPriceFeed); //we're pushing 2 separate weth addresses

        vm.expectRevert(
            abi.encodeWithSelector(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector)
        );
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    // function testConstructorSetsMappingsAndArrayCorrectly() public { **Should fix this test**
    //     assertEq(engine.getCollateralTokens[0], weth);
    //     assertEq(engine.getCollateralTokens[1], wbtc);
    //     assertEq(engine.getCollateralTokenPriceFeed[0], wethUsdPriceFeed);
    //     assertEq(engine.getCollateralTokenPriceFeed[1], wbtcUsdPriceFeed);
    // }

    //Price Tests

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdValue = 30000e18;
        uint256 usdValue = engine.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsdValue);
    }

    function testGetTokenAmountFromUsdValue() public view {
        uint256 usdValue = 30000e18;
        uint256 expectedTokenAmount = 15e18;
        uint256 tokenAmount = engine.getTokenAmountFromUsdValue(weth, usdValue);
        assertEq(tokenAmount, expectedTokenAmount);
    }

    //Deposit Collateral Tests

    function testRevertIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__NeedsMoreThanZero.selector));
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertIfTokenNotAllowed() public {
        ERC20Mock randomToken = new ERC20Mock("Random Token", "RND");

        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(randomToken)));
        engine.depositCollateral(address(randomToken), COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), COLLATERAL_AMOUNT);
        engine.depositCollateral(weth, COLLATERAL_AMOUNT);
        _;
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedAmountDeposited = engine.getUsdValue(weth, COLLATERAL_AMOUNT);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(collateralValueInUsd, expectedAmountDeposited);
    }
}
