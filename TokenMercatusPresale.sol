pragma solidity ^0.4.17;

import 'browser/IERC20.sol';
import 'browser/SafeMath.sol';

contract TokenMercatusPresale is IERC20 {
    
    using SafeMath for uint256;

    uint256 private _totalSupply = 0;
    string public constant symbol = "Pre-MCS";
    string public constant name = "Mercatus Presale Token";
    uint8 public constant decimals = 0;
    address public admin;

    mapping(address => uint8) investors; // list of the owner approved investors
    mapping(address => uint256) payed; // how much eth user invested
    uint256 public totalEth = 0;
    uint256[4] buyVolumes;
    uint256[4] bonuses;
    uint256 public constant rate = 15600; // 1 eth = 15600 tokens
    uint256 softCap = 230 ether;
    uint256 hardCap = 385 ether;
    uint256 lastMaxBuy = 40 ether;

    // ============ Standard ERC20 token functionality =================
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function TokenMercatusPresale(address _admin) public {
        admin = _admin;
        
        buyVolumes[0] = 10 ether;
        buyVolumes[1] = 50 ether;
        buyVolumes[2] = 100 ether;
        buyVolumes[3] = 100000 ether;
        
        bonuses[1] = 10;
        bonuses[2] = 20;
        bonuses[3] = 30;
    }
    
    function totalSupply() public constant returns (uint256 __totalSupply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        // SafeMath.sub will throw if there is not enough balance
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) transferAllowed public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // ============ Investor approve =================

    function addInvestor(address a) onlyAdmin public {
        investors[a] = 1;
    }
    function removeInvestor(address a) onlyAdmin public {
        investors[a] = 0;
    }

    // ============ Create and sell tokens =================

    function createTokens() whenNotPaused public payable {
        require(investors[msg.sender] == 1);
        require(msg.value >= buyVolumes[0]);
        require(totalEth < hardCap);
        
        uint256 maxBuy = hardCap.sub(totalEth);
        if (maxBuy < lastMaxBuy) maxBuy = lastMaxBuy;
        require(msg.value <= maxBuy);
        
        uint256 bonus = 0;
        for (uint i = 0; i < buyVolumes.length; i++) {
            if (msg.value < buyVolumes[i]) {
                bonus = bonuses[i];
                break;
            }
        }
        require(bonus != 0);
        
        uint256 tokens = msg.value.div(1 ether).mul(rate);
        tokens = tokens.mul(bonus.add(100)).div(100);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        payed[msg.sender] = payed[msg.sender].add(msg.value);
        _totalSupply = _totalSupply.add(tokens);
        totalEth += msg.value;
    }
    
    function () public payable {
        createTokens();
    }

    function payedOf(address _owner) public constant returns (uint256 _payed) {
        return payed[_owner];
    }

    // ============ Start/stop selling process =================
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event Pause(bytes32 caption, bool p);
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause(bool p) onlyAdmin public {
        paused = p;
        Pause("Pause", p);
    }
    
    
    bool public allowTransfer = false;
    
    modifier transferAllowed() {
        require(allowTransfer);
        _;
    }

    function allowTransfer(bool p) onlyAdmin public {
        allowTransfer = p;
    }

    // ============ Withdraw =================

    event Withdraw(bytes32 caption, address owner, uint256 amount);

    function withdraw() whenPaused public {
        require(balances[msg.sender] > 0);
        require(totalEth < softCap);
        
        msg.sender.transfer(payed[msg.sender]);
        Withdraw("Withdraw", msg.sender, payed[msg.sender]);

        _totalSupply = _totalSupply.sub(balances[msg.sender]);
        totalEth = totalEth.sub(payed[msg.sender]);
        payed[msg.sender] = 0;
        balances[msg.sender] = 0;
    }    
    
    event WithdrawToAdmin(bytes32 caption, uint256 amount);

    function withdrawToAdmin() onlyAdmin public {
        require(totalEth >= softCap);
        WithdrawToAdmin("WithdrawToAdmin", this.balance);
        admin.transfer(this.balance);
    }
}