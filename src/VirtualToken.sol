// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LaunchPadUtils} from "./Utils/LaunchPadUtils.sol";

contract VirtualToken is ERC20, ReentrancyGuard {
    address public mutiSigAdmin;
    address public factory;
    address public underlyingToken;
    uint256 public cashOutFee;
    uint256 public constant MAX_LOAN_PER_BLOCK = 300 ether;
    uint256 public lastLoanBlock;
    uint256 public loanedAmountThisBlock;

    mapping(address => uint256) public _debt;
    mapping(address => bool) public whiteList;

    event LoanTaken(address user, uint256 amount);
    event LoanRepaid(address user, uint256 amount);
    event Wrap(address user, uint256 amount);
    event Unwrap(address user, uint256 amount);
    event Withdraw(address mutiSigAdmin, uint256 amount);

    error DebtOverflow(address user, uint256 debt, uint256 value);

    modifier onlyWhiteListed() {
        require(whiteList[msg.sender], "Only WhiteList");
        _;
    }

    modifier onlyMutiSigAdmin() {
        require(msg.sender == mutiSigAdmin, "Only mutiSigAdmin can call this function");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call this function");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _underlyingToken,
        address _mutiSigAdmin
    ) ERC20(name, symbol) {
        underlyingToken = _underlyingToken;
        mutiSigAdmin = _mutiSigAdmin;
        cashOutFee = 20;
    }

    function updateFactory(address _factory) external onlyMutiSigAdmin {
        factory = _factory;
    }

    function updateCashOutFee(uint256 _cashOutFee) external onlyMutiSigAdmin {
        cashOutFee = _cashOutFee;
    }

    function addToWhiteList(address user) external onlyMutiSigAdmin {
        whiteList[user] = true;
    }

    function removeFromWhiteList(address user) external onlyMutiSigAdmin {
        whiteList[user] = false;
    }

    function getCashOutQuote(uint256 amount) public view returns (uint256 amountAfterFee) {
        uint256 fee = (amount * cashOutFee) / 10000;
        amountAfterFee = amount - fee;
    }

    function cashIn() external payable onlyWhiteListed {
        _transferAssetFromUser(msg.value);
        _mint(msg.sender, msg.value);
        emit Wrap(msg.sender, msg.value);
    }

    function cashOut(uint256 amount) external onlyWhiteListed returns (uint256 amountAfterFee) {
        amountAfterFee = getCashOutQuote(amount);

        _burn(msg.sender, amount);
        _transferAssetToUser(amountAfterFee);
        emit Unwrap(msg.sender, amountAfterFee);
    }

    function takeLoan(address to, uint256 amount) external payable nonReentrant onlyFactory {
        if (block.number > lastLoanBlock) {
            lastLoanBlock = block.number;
            loanedAmountThisBlock = 0;
        }
        require(loanedAmountThisBlock + amount <= MAX_LOAN_PER_BLOCK, "Loan limit per block exceeded");

        loanedAmountThisBlock += amount;
        _mint(to, amount);
        _increaseDebt(to, amount);

        emit LoanTaken(to, amount);
    }

    function repayLoan(uint256 amount) external nonReentrant onlyFactory {
        _burn(msg.sender, amount);
        _decreaseDebt(msg.sender, amount);

        emit LoanRepaid(msg.sender, amount);
    }

    function getLoanDebt(address user) external view returns (uint256) {
        return _debt[user];
    }

    function _increaseDebt(address user, uint256 amount) internal {
        _debt[user] += amount;
    }

    function _decreaseDebt(address user, uint256 amount) internal {
        _debt[user] -= amount;
    }

    function _transferAssetFromUser(uint256 amount) internal {
        if (underlyingToken == LaunchPadUtils.NATIVE_TOKEN) {
            require(msg.value >= amount, "Invalid ETH amount");
        } else {
            IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);
        }
    }

    function _transferAssetToUser(uint256 amount) internal {
        if (underlyingToken == LaunchPadUtils.NATIVE_TOKEN) {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(underlyingToken).transfer(msg.sender, amount);
        }
    }

    // override the _update function to prevent overflow
    function _update(address from, address to, uint256 value) internal override {
        // check: balance - _debt < value
        if (from != address(0) && balanceOf(from) < value + _debt[from]) {
            revert DebtOverflow(from, _debt[from], value);
        }

        super._update(from, to, value);
    }

    function withdraw(uint256 amount) external onlyMutiSigAdmin nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(mutiSigAdmin).transfer(amount);
        emit Withdraw(mutiSigAdmin, amount);
    }
}