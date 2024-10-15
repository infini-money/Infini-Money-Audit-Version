import {BaseTest} from "./BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";

contract LiquidityManage  is BaseTest {

    function setUp() public override {
        super.setUp();

        vm.startPrank(multiSigAdmin);
        vETH.addToWhiteList(multiSigAdmin);
        vm.stopPrank();
    }

    function test_mint_and_redeem() public {
        deal(multiSigAdmin, 100 ether);
        uint256 beforeAmount = payable(multiSigAdmin).balance;
        vm.startPrank(multiSigAdmin);

        vETH.cashIn{value: 10 ether}();
        vm.assertEq(vETH.balanceOf(multiSigAdmin), 10 ether);

        uint256 beforeCashOutBalance = payable(multiSigAdmin).balance;

        vETH.cashOut(10 ether);

        uint256 cashOutAmount = vETH.getCashOutQuote(10 ether);
        vm.assertEq(payable(multiSigAdmin).balance, beforeCashOutBalance + cashOutAmount) ;
        vm.stopPrank();
    }

    function test_liquidityV3() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboTokenV2", "LAMBO", 10 ether, address(vETH));

        // create VETH <-> WETH uniswapV3 Pool
        deal(multiSigAdmin, 100 ether);
        uint256 beforeAmount = payable(multiSigAdmin).balance;
        vm.startPrank(multiSigAdmin);

        vETH.cashIn{value: 10 ether}();
        vm.assertEq(vETH.balanceOf(multiSigAdmin), 10 ether);

        vm.stopPrank();
    }

    // 0. createLaunchPad, loan 10ether
    // 1. buy 10 ehter, get nearly 50M
    // 2. addVirtualLiquidity(12 ether)
    // 3, Sell Left tokens, get nearly 6.4 ether
    function test_addVirtualLiquidity() public {
        (address quoteToken, address pool) = factory.createLaunchPad("LamboTokenV2", "LAMBO", 10 ether, address(vETH));

        // buy-in
        deal(multiSigAdmin, 100 ether);
        vm.startPrank(multiSigAdmin);

        uint256 amountOut = lamboRouter.buyQuote{value: 10 ether}(quoteToken, 10 ether, 0);
        // nearly 0.5M
        vm.assertGt(amountOut, 0);

        vm.stopPrank();

        console2.log("user quoteTokenBalance(0): ", IERC20(quoteToken).balanceOf(multiSigAdmin));

        // addVirtualLiquidity
        vm.startPrank(multiSigAdmin);
        IERC20(quoteToken).approve(address(factory), amountOut);
        (uint256 amountB) = factory.addVirtualLiquidity(
            address(vETH),
            quoteToken,
            12 ether,
            0
        );

        console2.log("user quoteTokenBalance(1): ", IERC20(quoteToken).balanceOf(multiSigAdmin));
        console2.log("amountB: ", amountB);
        
        vm.assertGt(amountB, 0);
        vm.stopPrank();

        // sell amountOut
        vm.startPrank(multiSigAdmin);
        uint256 amountYIn = IERC20(quoteToken).balanceOf(multiSigAdmin);
        IERC20(quoteToken).approve(address(lamboRouter), amountYIn);
        uint256 amountXOut = lamboRouter.sellQuote(quoteToken, amountYIn, 0);
        vm.assertGt(amountXOut, 0);

        console2.log("amountYIn final: ", amountYIn);
        console2.log("amountXOut final: ", amountXOut);

        vm.stopPrank();

    }

}
