
import {BaseTest} from "./BaseTest.t.sol";

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

        vETH.cashOut(10 ether);
        vm.assertEq(payable(multiSigAdmin).balance, 100 ether);
        vm.stopPrank();
    }

}
