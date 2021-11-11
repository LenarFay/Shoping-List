pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "IShopp.sol";
import "ShoppDebot.sol";

contract ShoppingInStore is ShoppDebot{

    function _menu() public override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You bought {} goods for the total amount of {}, you have {} goods left to buy",
                    m_stat.buy,
                    m_stat.totalPrice,
                    m_stat.notBuy
            ),
            sep,
            [
                MenuItem("Make purchase to list","",tvm.functionId(makePurchase)),
                MenuItem("Show shopping list","",tvm.functionId(showPurchases)),
                MenuItem("Remove purchase from list","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function makePurchase(uint32 index) public {
        index = index;
        if (m_stat.notBuy > 0) {
            Terminal.input(tvm.functionId(makePurchase_), "Enter the purchase number:", false);
        } else {
            if (m_stat.buy > 0) {
                Terminal.print(0, "You bought everything. Shopping is over");
            } else {
                Terminal.print(0, "Sorry, your list is empty");
            }
            _menu();
        }
    }

    function makePurchase_(string value) public {
        (uint256 num, bool status) = stoi(value);
        if (status) {
            m_purchaseId = uint32(num);
            ConfirmInput.get(tvm.functionId(makePurchase__),"Are you ready to buy?");
        } else {          
            Terminal.input(tvm.functionId(makePurchase_), "Incorrect purchase number (must be an integer)", false);                      
        }    

    }

    function makePurchase__(bool value) public {
        buy = value;
        if (buy) {
            Terminal.input(tvm.functionId(makePurchase___), "Purchase price:", false);
        } else {
            _menu();
        }
    }

    function makePurchase___(string value) public {
        (uint256 _price, bool status) = stoi(value);
        if (status) {
            optional(uint256) pubkey = 0;
            IShopping(m_address).makePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_purchaseId, buy, _price);
        } else {          
            Terminal.input(tvm.functionId(makePurchase___), "Incorrect purchase price (must be an integer):", false);                   
        }
    }

    function showPurchases(uint32 index) public view {
        index = index;
        optional(uint256) none;
        IShopping(m_address).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchases_),
            onErrorId: 0
        }();
    }

    function showPurchases_(Purchase[] purchases) public {
        uint32 i;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your purchases list:");
            for (i = 0; i < purchases.length; i++) {
                Purchase purchase = purchases[i];
                string completed;
                if (purchase.isBuy) {
                    completed = '✓';
                    Terminal.print(0, format("{} {}  \"{}\"  quantity: {}, price: {}, at {}", purchase.id, completed, purchase.text, purchase.val, purchase.price, purchase.time));
                } else {
                    completed = ' ';
                    Terminal.print(0, format("{} {}  \"{}\"  quantity: {}, at {}", purchase.id, completed, purchase.text, purchase.val, purchase.time));
                }
            }
        } else {
            Terminal.print(0, "Your shopping list is empty");
        }
        _menu();
    }

    function deletePurchase(uint32 index) public {
        index = index;
        if (m_stat.buy + m_stat.notBuy > 0) {
            Terminal.input(tvm.functionId(deletePurchase_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Your shopping list is empty");
            _menu();
        }
    }

    function deletePurchase_(string value) public {
        (uint256 num, bool status) = stoi(value);
        if (status) {
            optional(uint256) pubkey = 0;
            IShopping(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
                }(uint32(num));
        } else {          
            Terminal.input(tvm.functionId(deletePurchase_), "Incorrect purchase number (must be an integer)", false);                     
        }
    }

}
