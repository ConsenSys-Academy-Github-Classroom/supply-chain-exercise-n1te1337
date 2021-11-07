// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;
  mapping (uint => Item) private items;
  enum State{ ForSale, Sold, Shipped, Received }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /*
   * Events
   */

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  /*
   * Modifiers
   */

  modifier isOwner {
    require(owner == msg.sender);
    _;
  }

  modifier verifyCaller (address _address) {
    require (msg.sender == _address);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    Item memory item = items[_sku];
    item.buyer.transfer(msg.value - item.price);
  }

  modifier forSale(uint _sku) {
    Item memory item = items[_sku];
    require(item.seller != address(0) && item.state == State.ForSale);
    _;
  }

  modifier sold(uint _sku) {
    Item memory item = items[_sku];
    require(item.seller != address(0) && item.state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    Item memory item = items[_sku];
    require(item.seller != address(0) && item.state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    Item memory item = items[_sku];
    require(item.seller != address(0) && item.state == State.Received);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });

    skuCount = skuCount + 1;

    emit LogForSale(skuCount);

    return true;
  }

  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku) {
    Item storage item = items[_sku];

    item.seller.transfer(item.price);
    item.buyer = msg.sender;
    item.state = State.Sold;

    emit LogSold(_sku);
  }

  function shipItem(uint _sku) public sold(_sku) verifyCaller(items[_sku].seller) {
    items[_sku].state = State.Shipped;

    emit LogShipped(_sku);
  }

  function receiveItem(uint _sku) public shipped(_sku) verifyCaller(items[_sku].buyer) {
    items[_sku].state = State.Received;

    emit LogReceived(_sku);
  }

  function fetchItem(uint _sku) public view returns (
    string memory name,
    uint sku,
    uint price,
    uint state,
    address seller,
    address buyer
  ) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;

    return (name, sku, price, state, seller, buyer);
  }
}
