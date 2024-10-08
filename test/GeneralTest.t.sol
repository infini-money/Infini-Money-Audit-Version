import {BaseTest} from "./BaseTest.t.sol";
import {LaunchPadUtils} from "../src/Utils/LaunchPadUtils.sol";
import {IStableNGFactory} from "../src/interfaces/Curve/IStableNGFactory.sol";
import {IUniswapV2Router01} from "../src/interfaces/Uniswap/IUniswapV2Router01.sol";
import {IStableNGPool} from "../src/interfaces/Curve/IStableNGPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregationRouterV6, IWETH} from "../src/libraries/1inchV6.sol";
import "forge-std/console2.sol";

contract GeneralTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }
    
    // vETH <-> Meme into Uniswap
    function test_createLaunchPad_with_virtual_token_and_buy_sell() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboTokenV2", "LAMBO", 10 ether, address(vETH));
        
        uint256 amountQuoteOut = lamboRouter.getBuyQuote(quoteToken, 10 ether);
        uint256 gasStart = gasleft();
        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        uint256 gasUsed = gasStart - gasleft();

        require(amountOut == amountQuoteOut, "getBuyQuote error");

        // 123544
        console2.log("BuyQuote Gas Used: ", gasUsed);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(this)), amountOut);

        IERC20(quoteToken).approve(address(lamboRouter), amountOut);
        
        amountQuoteOut = lamboRouter.getSellQuote(quoteToken, amountOut);
        gasStart = gasleft();
        uint256 amountXOut = lamboRouter.sellQuote(quoteToken, amountOut, 0);
        gasUsed = gasStart - gasleft();

        require(amountQuoteOut == amountXOut);
        // 111287
        console2.log("SellQuote Gas Used: ", gasUsed);

        // nearly 0.003
        console2.log("amountXOut: ", amountXOut);
        
    }

        // vETH <-> Meme into Uniswap
    function test_createLaunchPadWithInitalBuy() public {
        (address quoteToken, address pool, uint256 amountYOut) = lamboRouter.createLaunchPadAndInitialBuy{value: 10 ether}("LamboTokenV2", "LAMBO", 10 ether, address(vETH), 10 ether);
  
        console2.log("amountYOut: ", amountYOut);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(this)), amountYOut);
        IERC20(quoteToken).approve(address(lamboRouter), amountYOut);
        
        uint256 gasStart = gasleft();
        uint256 amountXOut = lamboRouter.sellQuote(quoteToken, amountYOut, 0);
        uint256 gasUsed = gasStart - gasleft();
        // 111287
        console2.log("SellQuote Gas Used: ", gasUsed);

        // nearly 0.003
        console2.log("amountXOut: ", amountXOut);
    }

    function test_cashIn_and_withdraw() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboTokenV2", "LAMBO", 10 ether, address(vETH));
        uint256 amountQuoteOut = lamboRouter.getBuyQuote(quoteToken, 10 ether);
        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        
        require(amountOut == amountQuoteOut, "getBuyQuote error");

        // withdraw gas 
        vm.startPrank(multiSigAdmin);
        uint256 initialBalance = address(multiSigAdmin).balance;
        vETH.withdraw(10 ether);
        uint256 finalBalance = address(multiSigAdmin).balance;
        assert(finalBalance == initialBalance + 10 ether);
        vm.stopPrank();
    }

    function test_create_uniswapV3_pool() public {
        

    }


    // vETH <-> ETH into Curve
    // function test_createPool_ETHAndvETH_on_Curve() public {
    //     address[] memory coins = new address[](2);
    //     coins[0] = WETH;
    //     coins[1] = address(vETH);

    //     uint8[] memory asset_types = new uint8[](2);
    //     asset_types[0] = 0;
    //     asset_types[1] = 0;

    //     bytes4[] memory method_ids = new bytes4[](2); // 修改这里
    //     method_ids[0] = bytes4(0x00000000);
    //     method_ids[1] = bytes4(0x00000000);

    //     address[] memory oracles = new address[](2);
    //     oracles[0] = address(0);
    //     oracles[1] = address(1);

    //     address curvePool = IStableNGFactory(curveStableNGFactoryAddress).deploy_plain_pool(
    //         "ETH/vETH", 
    //         "ETH/vETH", 
    //         coins, 
    //         250, 
    //         4000000, 
    //         20000000000, 
    //         866, 
    //         0, 
    //         asset_types, 
    //         method_ids, 
    //         oracles
    //     );

    //     uint256[] memory _amounts = new uint256[](2);
    //     _amounts[0] = 10 ether;
    //     _amounts[1] = 10 ether;

    //     deal(coins[0], address(this), 10 ether);
    //     deal(coins[1], address(this), 10 ether);

    //     IERC20(coins[0]).approve(curvePool, 10 ether);
    //     IERC20(coins[1]).approve(curvePool, 10 ether);

    //     IStableNGPool(curvePool).add_liquidity(_amounts, 0, address(this));

    // }

    // function test_1inchV6_aggregator_from_Curve_to_UnsiwapV2() public {
    //     // 1inchV6 Router 地址
    //     // 替换为实际的1inchV6 Router地址

    //     address routerAddress = 0xE37e799D5077682FA0a244D46E5649F71457BD09 
    //     IAggregationExecutor executor = IAggregationExecutor(routerAddress);

    //     // SwapDescription 设置
    //     IAggregationRouterV6.SwapDescription memory desc;
    //     desc.srcToken = IERC20(address(0)); // ETH
    //     desc.dstToken = IERC20(address(vETH)); // vETH
    //     desc.srcReceiver = payable(address(this));
    //     desc.dstReceiver = payable(address(this));
    //     desc.amount = 10 ether;
    //     desc.minReturnAmount = 1 ether; // 设置最小返回值
    //     desc.flags = 0; // 根据需要设置标志

    //     // 编码的调用数据
    //     bytes memory data = abi.encodeWithSelector(
    //         IAggregationRouterV6.swap.selector,
    //         executor,
    //         desc,
    //         abi.encodeWithSelector(
    //             IAggregationRouterV6.swap.selector,
    //             executor,
    //             desc,
    //             abi.encodeWithSelector(
    //                 IAggregationRouterV6.swap.selector,
    //                 executor,
    //                 desc,
    //                 new bytes(0) // 这里可以添加更多的调用数据
    //             )
    //         )
    //     );

    //     // 调用 swap 函数
    //     (uint256 returnAmount, uint256 spentAmount) = IAggregationRouterV6(routerAddress).swap{value: 10 ether}(
    //         executor,
    //         desc,
    //         data
    //     );

    //     // 验证结果
    //     require(returnAmount >= desc.minReturnAmount, "Return amount is not enough");
    // }
    receive() external payable {}
}
