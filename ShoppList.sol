pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "IShopp.sol";

contract ShoppList {

    uint32 m_count;

    mapping(uint32 => Purchase) m_product;

    uint256 ownerPubkey;

    modifier onlyOwner() {
        require(msg.pubkey() == ownerPubkey, 101);
        _;
    }    

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 123);
        tvm.accept();
        ownerPubkey = pubkey;
    }

    function createPurchase(string text, uint val) public onlyOwner {
        tvm.accept();
        m_count++;
        m_product[m_count] = Purchase(m_count, text, val, now, false, 0);
    }

    function makePurchase(uint32 id, bool done, uint price) public onlyOwner {
        optional(Purchase) purchase = m_product.fetch(id);
        require(purchase.hasValue(), 102);
        tvm.accept();
        Purchase thisPurchase = purchase.get();
        thisPurchase.isBuy = done;
        thisPurchase.price = price;
        m_product[id] = thisPurchase;
    }

    function deletePurchase(uint32 id) public onlyOwner {
        require(m_product.exists(id), 102);
        tvm.accept();
        delete m_product[id];
    }

    function getPurchases() public view returns (Purchase[] purchases) {
        string text;
        uint val;
        uint64 creationTime;
        bool paid;
        uint price;

        for((uint32 id, Purchase purchase) : m_product) {
            text = purchase.text;
            val = purchase.val;
            paid = purchase.isBuy;
            creationTime = purchase.time;
            price = purchase.price;
            purchases.push(Purchase(id, text, val, creationTime, paid, price));
       }
    }

    function getStat() public view returns (Stat stat) {
        uint notPurchased;
        uint purchased;
        uint totalPrice;

        for((, Purchase purchase) : m_product) {
            if (purchase.isBuy) {
                    purchased += purchase.val;
                    totalPrice += purchase.price;
                } else {
                    notPurchased += purchase.val;
                }
        }
        stat = Stat(notPurchased, purchased, totalPrice);
    }
}

