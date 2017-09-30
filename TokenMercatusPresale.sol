pragma solidity ^0.4.17;

import 'browser/IERC20.sol';
import 'browser/SafeMath.sol';

contract TokenMercatusPresale is IERC20 {
    
    using SafeMath for uint256;

    uint256 private _totalSupply = 0;
    string public constant symbol = "PreMCS";
    string public constant name = "Mercatus Presale Token";
    uint8 public constant decimals = 18;
    uint256 public constant rate = 500; // 1 eth = 500 PreMcs
    uint256 public constant minBuyinEther = 40; // Minimum buyin is 40 eth
    address public owner;
    
    // ============ Standard ERC20 token functionality =================
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function TokenMercatusPresale(address _owner) public {
        owner = _owner;
    }
    
    function totalSupply() public constant returns (uint256 __totalSupply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
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

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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

    // ============ Create and sell tokens =================

    function createTokens() whenNotPaused public payable {
        require(msg.value >= minBuyinEther);
        uint256 tokens = msg.value.mul(rate);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        
        owner.transfer(msg.value);
    }
    function () public payable {
        createTokens();
    }

    // ============ Start/stop selling process =================
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event Pause(bytes32 caption, bool p);
    
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    function pause(bool p) onlyOwner public {
        paused = p;
        Pause("Pause", p);
    }
    
}