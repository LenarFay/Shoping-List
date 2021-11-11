pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../base/Sdk.sol";
import "../base/Debot.sol";
import "../base/Terminal.sol";
import "../base/ConfirmInput.sol";
import "../base/AddressInput.sol";
import "../base/Menu.sol";
import "../base/Upgradable.sol";

import "IShopp.sol";

abstract contract ShoppDebot is Debot {
    bytes m_icon;

    TvmCell m_shoppingCode; 
    TvmCell m_shoppingData; 
    TvmCell m_shoppingStateInit; 
    address m_address;      
    Stat m_stat;            
    uint32 m_purchaseId;    
    string productName;     
    bool buy;               
    uint256 m_masterPubKey; 
    address m_msigAddress;  

    uint32 INITIAL_BALANCE =  200000000;  

    function setShopingCode(TvmCell code,TvmCell data) public {
	require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_shoppingCode = code;
        m_shoppingData = data;
        m_shoppingStateInit = tvm.buildStateInit(m_shoppingCode, m_shoppingData);
    }

    function start() public override {
        Terminal.input(tvm.functionId(receivePublicKey),"Please enter your public key",false);
    }

    
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Shoping DeBot";
        version = "0.2.0";
        publisher = "Lenar Fayzullin";
        key = "Shop list manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a shoping DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function receivePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a shopping list ...");
            TvmCell deployState = tvm.insertPubkey(m_shoppingStateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your Shop List contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(receivePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getStat(tvm.functionId(setStat));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. You will need to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deployment of a new contract. If an error occurs, check if your Shop List contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function _menu() virtual public  { 
        
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        IMsig(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitingDeploy),
            onErrorId: tvm.functionId(repeatCredit)  
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function deploy() private view {
        TvmCell image = tvm.insertPubkey(m_shoppingStateInit, m_masterPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: m_address,
            callbackId: tvm.functionId(onSuccess),
            onErrorId:  tvm.functionId(repeatDeploy),    
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {AShopp, m_masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function repeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        sdkError;
        exitCode;
        deploy();
    }

    function repeatCredit(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }

    function onSuccess() public view {
        _getStat(tvm.functionId(setStat));
    }

    function waitingDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkStatusUnInit), m_address);
    }

    function checkStatusUnInit(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitingDeploy();
        }
    }

    function setStat(Stat stat) public {
        m_stat = stat;
        uint32 i;
        _menu();
    }

    function _getStat(uint32 Id) private view {
        optional(uint256) none;
        IShopping(m_address).getStat{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: Id,
            onErrorId: 0
        }();
    }
}