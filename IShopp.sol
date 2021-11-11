pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct Purchase {
    uint32 id;
    string text;
    uint val;
    uint64 time;
    bool isBuy;
    uint price;
}

struct Stat {
    uint notBuy;
    uint buy;
    uint totalPrice;
}

interface IMsig {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload  ) external;
}


abstract contract AShopp {
   constructor(uint256 pubkey) public {}
}

interface IShopping {
   function createPurchase(string text, uint val) external;
   function makePurchase(uint32 id, bool done, uint price) external;
   function getStat() external returns (Stat);
   function deletePurchase(uint32 id) external;
   function getPurchases() external returns (Purchase[] purchases);
   
}