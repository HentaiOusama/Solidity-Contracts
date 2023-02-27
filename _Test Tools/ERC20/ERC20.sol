// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public returns(bool) {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }
}

contract OppaiToken is ERC20Interface, Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        symbol = "( . Y . )";
        name = "Oppai Coin";
        decimals = 18;
        _totalSupply = 10000000000 * 10**uint(decimals);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    
    function mint(address to, uint tokens) public onlyOwner returns (bool) {
        _totalSupply += tokens;
        balances[to] += tokens;
        emit Transfer(address(0), to, tokens);
        return true;
    }
    
    function burn(uint tokens) public returns (bool) {
        _totalSupply -= tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address _from, address to, uint tokens) public override returns (bool success) {
        balances[_from] -= tokens;
        allowed[_from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(_from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}
