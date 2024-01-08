// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

pragma experimental ABIEncoderV2;

abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return payable(msg.sender);
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this;
            return msg.data; 
        }
    }

library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;  
            require(c >= a, "SafeMath: addition overflow");
            return c;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        function sub(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;
            return c;
        }

        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
            }
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;
        }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            return c;
        }

        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }

        function mod(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
}

interface IERC20 {

        function totalSupply() external view  returns (uint256);

        function balanceOf(address account) external view returns (uint256);

        function transfer(address recipient, uint256 amount)
            external
            returns (bool);

        function allowance(address owner, address spender)
            external
            view
            returns (uint256);

        function approve(address spender, uint256 amount) external returns (bool);

        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) external returns (bool);

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
    }

contract DigiFortune is Context, IERC20 {
        using SafeMath for uint256;
        mapping(address => uint256) public _balances;
        mapping(address => bool) private  blacklist;
        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 public override totalSupply;
        string public  name;
        string public symbol;
        uint8 public decimals;
        address internal owner;
        address [] internal blacklistAddresses;

        constructor() {
            name = "DigiFortune";
            symbol = "DIFO";
            totalSupply = 1000000000000e18;
            decimals = 18;

            owner = msg.sender;
            _balances[owner] = totalSupply;
            _paused = false;
            emit Transfer(address(0), owner, totalSupply);
        }

        modifier onlyOwner() {
            require(msg.sender == owner, "Only Call by Owner");
            _;
        }

        event DestroyedBlackFunds(address _blackListedUser, uint _balance);

        event multiTransferTokens(address indexed sender, address indexed recipient, uint256 amount);

        event BlackListed(address _user);

        event RemovedBlackList(address _user);

        event Paused(address account);

        event Unpaused(address account);

        bool private _paused;

        function paused() public view virtual returns (bool) {
            return _paused;
        }

        modifier whenNotPaused() {
            require(!paused(), "Pausable: paused");
            _;
        }

        modifier whenPaused() {
            require(paused(), "Pausable: not paused");
            _;
        }

        function _pause() internal virtual whenNotPaused {
            _paused = true;
            emit Paused(msg.sender);
        }

        function _unpause() internal virtual whenPaused {
            _paused = false;
            emit Unpaused(msg.sender);
        }

        function pauseContract() public onlyOwner {
            _pause();
        }

        function unpauseContract() public onlyOwner {
            _unpause();
        }

        function balanceOf(address account) public view override returns (uint256) {
            return _balances[account];
        }

        function transfer(address recipient, uint256 amount)
            public
            virtual
            override
            whenNotPaused
            returns (bool)
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function allowance(address _owner, address spender)
            public
            view
            virtual
            override
            returns (uint256)
        {
            return _allowances[_owner][spender];
        }

        function approve(address spender, uint256 amount)
            public
            virtual
            override
            returns (bool)
        {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public virtual override whenNotPaused returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue)
            public
            virtual
            whenNotPaused
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender].add(addedValue)
            );
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue)
            public
            virtual
            whenNotPaused
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender].sub(
                    subtractedValue,
                    "ERC20: decreased allowance below zero"
                )
            );
            return true;
        }
 
        function _transfer(
        address sender,
        address recipient,
          uint256 amount
        ) internal virtual whenNotPaused {
          require(sender != address(0), "ERC20: transfer from the zero address");
          require(recipient != address(0), "ERC20: transfer to the zero address");
          require(blacklist[sender] == false, "you are blacklisted");
          require(blacklist[recipient] == false, "you are blacklisted");
          _beforeTokenTransfer(sender, recipient, amount);
          _balances[sender] = _balances[sender].sub(
              amount,
           "ERC20: transfer amount exceeds balance"
            );
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
        }

        function _approve  (
            address _owner,
            address spender,
            uint256 amount
        ) internal virtual whenNotPaused {
            require(_owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
            _allowances[_owner][spender] = amount;
            emit Approval(_owner, spender, amount);
        }

        function _mint(address account, uint256 amount) internal onlyOwner {
            require(account != address(0), "ERC20: mint to the zero address");
            _balances[account] = _balances[account].add(amount);
            totalSupply = totalSupply.add(amount); 
            emit Transfer(address(0), account, amount);
        }

        function multiTransfer(address[] calldata recipients, uint256 amount)
            external
            onlyOwner
            whenNotPaused
        {
            require(recipients.length > 0, "Recipient list is empty");

            for (uint256 i = 0; i < recipients.length; i++) {
                require(recipients[i] != address(0), "Invalid recipient address");
                require(!blacklist[recipients[i]], "Recipient is blacklisted");

                _transfer(_msgSender(), recipients[i], amount);
                emit multiTransferTokens(_msgSender(), recipients[i], amount);
            }
        }

        function _burn(address account, uint256 value) internal whenNotPaused onlyOwner {
            require(account != address(0), "ERC20: burn from the zero address");

            totalSupply = totalSupply.sub(value);
            _balances[account] = _balances[account].sub(value);
            emit Transfer(account, address(0), value);
        }

        function transferownership(address _newonwer)
            public
            whenNotPaused
            onlyOwner
        {
            owner = _newonwer;
        }
    
        function addToBlackList(address[] calldata accounts) external onlyOwner whenNotPaused {
         for (uint256 i = 0; i < accounts.length; i++) {
         address account = accounts[i];
         require(!isBlacklisted(account), "Address is already blacklisted");
         blacklistAddresses.push(account);
         blacklist[account] = true;
         emit BlackListed(account);

        }

        } 

        function isBlacklisted(address account) public onlyOwner view returns (bool) {
        for (uint256 i = 0; i < blacklistAddresses.length; i++) {
            if (blacklistAddresses[i] == account) {
                return true;
            }
        }
        return false;

        }

        function removefromblacklist() public onlyOwner whenNotPaused {
            for (uint256 i = 0; i < blacklistAddresses.length; i++) {
                blacklist[blacklistAddresses[i]] = false;
            }
            delete blacklistAddresses;
        }

        function destroyBlackFunds (address _blackListedUser) public onlyOwner {
            require(blacklist[_blackListedUser]);
            uint dirtyFunds = balanceOf(_blackListedUser);
            _balances[_blackListedUser] = 0;
            totalSupply -= dirtyFunds;
            emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
        }

        function withDrawBNB(uint256 _amount) public onlyOwner whenNotPaused {
            payable(msg.sender).transfer(_amount);
        }

        function getTokens(uint256 _amount) public onlyOwner whenNotPaused {
            _transfer(address(this), msg.sender, _amount);
        }

        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}

        function mint(address to, uint256 amount) public onlyOwner {
            _mint(to, amount);
        }

        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
       }

}
