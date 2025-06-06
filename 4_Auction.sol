// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Auction
 * @dev Contrato de subasta con funcionalidades avanzadas
 */
contract Auction {
    // Estructuras
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    // Variables de estado
    address public owner;
    string public itemName;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public auctionEnded;

    mapping(address => uint256) public deposits;
    Bid[] public bids;

    uint256 public constant MINIMUM_BID_INCREASE = 5; // 5%
    uint256 public constant COMMISSION_RATE = 2; // 2%
    uint256 public constant TIME_EXTENSION = 10 minutes;
    uint256 public constant EXTENSION_THRESHOLD = 10 minutes;

    // Eventos
    event NewBid(address indexed bidder, uint256 amount, uint256 timestamp);
    event AuctionEnded(address winner, uint256 winningBid);
    event RefundProcessed(address indexed bidder, uint256 amount);
    event PartialWithdrawal(address indexed bidder, uint256 amount);

    // Modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "La subasta ha finalizado");
        require(!auctionEnded, "La subasta ya fue cerrada");
        _;
    }

    modifier auctionFinished() {
        require(block.timestamp >= auctionEndTime || auctionEnded, "La subasta aun esta activa");
        _;
    }

    modifier validBid() {
        require(msg.value > 0, "La oferta debe ser mayor a 0");
        uint256 minimumBid = highestBid == 0 ? 1 : highestBid + (highestBid * MINIMUM_BID_INCREASE / 100);
        require(msg.value >= minimumBid, "La oferta debe ser al menos 5% mayor que la actual");
        _;
    }

    constructor(string memory _itemName, uint256 _auctionDuration) {
        require(_auctionDuration > 0, "La duracion debe ser mayor a 0");
        require(bytes(_itemName).length > 0, "El nombre del articulo no puede estar vacio");

        owner = msg.sender;
        itemName = _itemName;
        auctionEndTime = block.timestamp + _auctionDuration;
        auctionEnded = false;
        highestBid = 0;
    }

    function placeBid() external payable auctionActive validBid {
        deposits[msg.sender] += msg.value;
        highestBid = msg.value;
        highestBidder = msg.sender;

        bids.push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        if (auctionEndTime - block.timestamp <= EXTENSION_THRESHOLD) {
            auctionEndTime += TIME_EXTENSION;
        }

        emit NewBid(msg.sender, msg.value, block.timestamp);
    }

    function withdrawExcess() external auctionActive {
        require(deposits[msg.sender] > 0, "No tienes depositos");

        uint256 currentValidBid = getCurrentValidBid(msg.sender);
        uint256 excess = deposits[msg.sender] - currentValidBid;

        require(excess > 0, "No tienes exceso para retirar");

        deposits[msg.sender] = currentValidBid;

        (bool sent, ) = msg.sender.call{value: excess}("");
        require(sent, "Fallo en la transferencia");

        emit PartialWithdrawal(msg.sender, excess);
    }

    function endAuction() external onlyOwner {
        require(!auctionEnded, "La subasta ya fue finalizada");
        auctionEnded = true;
        auctionEndTime = block.timestamp; // Evita más ofertas
        emit AuctionEnded(highestBidder, highestBid);
    }

    function processRefunds() external auctionFinished {
        require(deposits[msg.sender] > 0, "No tienes depositos para reembolsar");
        require(msg.sender != highestBidder, "El ganador no puede recibir reembolso");

        uint256 refundAmount = deposits[msg.sender];
        uint256 commission = (refundAmount * COMMISSION_RATE) / 100;
        uint256 finalRefund = refundAmount - commission;

        deposits[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: finalRefund}("");
        require(sent, "Fallo en la transferencia");

        emit RefundProcessed(msg.sender, finalRefund);
    }

    function withdrawWinnings() external onlyOwner auctionFinished {
        require(highestBidder != address(0), "No hay ofertas validas");
        require(deposits[highestBidder] > 0, "Los fondos ya fueron retirados");

        uint256 winnings = deposits[highestBidder];
        deposits[highestBidder] = 0;

        (bool sent, ) = owner.call{value: winnings}("");
        require(sent, "Fallo en la transferencia");
    }

    function getWinner() external view returns (address winner, uint256 winningBid) {
        return (highestBidder, highestBid);
    }

    function getAllBids() external view returns (Bid[] memory) {
        return bids;
    }

    function getAuctionInfo() external view returns (
        string memory _itemName,
        uint256 _auctionEndTime,
        uint256 _highestBid,
        address _highestBidder,
        bool _auctionEnded,
        uint256 _totalBids
    ) {
        return (
            itemName,
            auctionEndTime,
            highestBid,
            highestBidder,
            auctionEnded || block.timestamp >= auctionEndTime,
            bids.length
        );
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= auctionEndTime || auctionEnded) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }

    function getCurrentValidBid(address bidder) internal view returns (uint256) {
        uint256 currentBid = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == bidder && bids[i].amount > currentBid) {
                currentBid = bids[i].amount;
            }
        }
        return currentBid;
    }

    function getDeposit(address bidder) external view returns (uint256) {
        return deposits[bidder];
    }

    function emergencyWithdraw() external onlyOwner {
        require(auctionEnded, "Solo disponible cuando la subasta haya terminado");

        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Fallo en la transferencia");
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
