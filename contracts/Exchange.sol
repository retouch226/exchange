// SPDX-License-Identifier: WTF

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cardano is ERC20{
    event Payment(address from, uint amount, uint time);
    address payable public  cardanoOwner;
    constructor() ERC20("Cardano", "ADA"){
        cardanoOwner = payable(msg.sender);
        _mint(cardanoOwner, 100000000000000000);
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
    receive() external payable{
        emit Payment(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() public payable{
        cardanoOwner.transfer(address(this).balance);
    }
}

    contract Tether is ERC20{
    event Payment(address from, uint amount, uint time);
    address payable public  tetherOwner;
    constructor() ERC20("Tether", "USDT"){
        tetherOwner = payable(msg.sender);
        _mint(tetherOwner, 100000000000000000);
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }

    receive() external payable{
       emit Payment(msg.sender, msg.value, block.timestamp);
        tetherOwner.transfer(address(this).balance);
    }
}

contract Zilliqa is ERC20{
    event Payment(address from, uint amount, uint time);
    address payable public  zilOwner;
    constructor() ERC20("Zil", "ZIL"){
        zilOwner = payable(msg.sender);
        _mint(zilOwner, 100000000000000000);
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
    receive() external payable{
        emit Payment(msg.sender, msg.value, block.timestamp);
        zilOwner.transfer(address(this).balance);
    }
}

contract Exchange{
ERC20 public tether;
ERC20 public cardano;
ERC20 public zilliqa;

uint immutable fee;
address payable owner;
struct User{address account; uint totalBalance; uint currenciesCount;}
User[] public _allUsers;
ERC20[] public _allCryptos;

mapping(address=>User) public _users;
mapping(address=>bool) public _usersBase;
//address=>tokenId=>amount
mapping(address=>mapping(uint=>uint)) _userTokensAmount;
mapping(ERC20=>uint) _tokensRate;
mapping(ERC20=>uint) _tokenToId;
mapping(uint=>ERC20) _idToToken;

event NewUser(address account, uint date);
event BoughtToken(address buyer, uint amount, uint rate, uint date);
event SellToken(address seller, uint amount, uint rate, uint date);
event Swap(address account, bytes32 from, uint fromAmount, bytes32 toAmount, uint date);
event Sender(address account);
event Balance(uint balance);

constructor(ERC20 _cardano, ERC20 _tether, ERC20 _zilliqa){
    owner = payable(msg.sender);
    fee = 100 wei;
    cardano = _cardano;
    tether = _tether;
    zilliqa = _zilliqa;
    _allCryptos.push(cardano);
    _allCryptos.push(tether);
    _allCryptos.push(zilliqa);
    for(uint i; i<_allCryptos.length; i++){
        _tokenToId[_allCryptos[i]] = i;
        _idToToken[i] = _allCryptos[i];
    }
    _tokensRate[tether] = 1;
    _tokensRate[cardano] = 20;
    _tokensRate[zilliqa] = 40;
}

function getTokenById(uint _id) public view returns(ERC20){
    return _idToToken[_id];
}

function getTokenIdByToken(ERC20 _token) public view returns(uint){
    return _tokenToId[_token];
}

function newUser() public returns(bool){
    require(msg.sender!=address(0), "not right account address");
    require(!_userExists(msg.sender), "user already exists");
    User memory _newUser = User(msg.sender, 0, 0);
    _allUsers.push(_newUser);
    _users[msg.sender] = _newUser;
    _usersBase[msg.sender] = true;
    emit NewUser(msg.sender, block.timestamp);
    return true;
}

function getUserTotalBalance(address account) public view returns(uint){
    return _users[account].totalBalance;
}

function getUserTokenAmount(address account, uint index) public view returns(uint){
    require(_userExists(account));
    return _userTokensAmount[account][index];
}

function _userExists(address account) public view returns(bool){
    return _usersBase[account];
}

// function swap(address token1, address token2, uint amount) external override returns(bool){
    
// }

function buyTokens(ERC20 token, address buyer, address tokensSeller) public payable returns(bool){
    uint amountOfWei = msg.value;
    _validateBeforePurchase(msg.sender, amountOfWei);
    uint amountTokens = _getTokensAmount(token, amountOfWei);
    // token.transferFrom(tokensSeller, buyer, amountTokens);
    bool result = _purchaseProcess(buyer, amountTokens, token,  tokensSeller);
    require(result, "tokens was not sent");
    //update buyer totalTokensBalance
    User storage  currentUser = _users[buyer];
    currentUser.totalBalance+=amountTokens;
    //update user tokensAmount
    uint tokenId = getTokenIdByToken(token);
    _userTokensAmount[buyer][tokenId] = amountTokens;
    _refund(amountOfWei - fee, token);
    _withdrawMoney(fee);
    emit BoughtToken(msg.sender, amountTokens, _tokensRate[token], block.timestamp);
    return true;
}



function sellToken(address token, uint amount) public returns(bool){}

function _purchaseProcess(address to, uint tokensAmount, ERC20 token, address  tokensSeller) public returns(bool){
    require(address(token)!=address(0), "token does not exists");
    require(tokensAmount>0, "you cant buy 0 tokens");
    emit Sender(msg.sender);
    token.transferFrom(tokensSeller, to, tokensAmount);
    return true;
}
// function sellToken(address token, uint amount) external override returns(bool);

// function setCurrencies(bytes[] memory _currenciesArray) public  {
//     for(uint i; i<_currenciesArray.length;i++){
//         currencies.push(bytes(_currenciesArray[i]));
//     }  
// }

function _validateBeforePurchase(address buyer , uint weiAmount) public view {
    require(_userExists(buyer), "user does not exist");
    require(buyer!=address(0), "address doesn't exists");
    require(weiAmount>0, "not enough funds");
    require(weiAmount>fee*2, "you need to pay at least 200 wei");
}

function _refund(uint amountOfWei, ERC20 token) public payable {
    payable(address(token)).transfer(amountOfWei);
}

function _withdrawMoney(uint feeAmount) internal {
    owner.transfer(feeAmount);
}

function _getTokensAmount(ERC20 token, uint weiAmount) internal view returns(uint){
    uint weiWithoutFee = weiAmount - fee;
    return weiWithoutFee / _tokensRate[token];
}

function getCurrencies() public view  returns(bytes[] memory){
    // return _currencies;
}

// receive() external payable{}

///////////////////////////////


}