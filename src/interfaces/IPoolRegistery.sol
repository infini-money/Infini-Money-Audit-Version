pragma solidity ^0.8.20;

interface IPoolRegistery {
    error OnlyAdmin();
    error OnlyValidFactory();

    // Events
    event RegisterFactory(address factory);
    event RegisterPool(address pool);
    event PoolCreated(address baseToken, address quoteToken, address pool);
    event ChangeAdmin(address oldAdmin, address newAdmin);
    
    function getPool(uint256 index) external view returns (address);
    function allPoolsLength() external view returns (uint256);
    function isPoolValid(address pool) external view returns (bool);
    function isPoolFactoryValid(address pool) external view returns (bool);
    function registerPool(address baseToken, address quoteToken, address pool) external;
}