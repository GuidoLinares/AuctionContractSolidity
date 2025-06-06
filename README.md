# AuctionContractSolidity

# Auction Smart Contract (Contrato Inteligente de Subasta)

Este repositorio contiene el código fuente de un contrato inteligente de subasta descentralizada desplegado en la red de prueba Sepolia.

## Descripción General

El contrato `Auction` permite a los usuarios participar en una subasta de un artículo específico. Incluye funcionalidades para realizar ofertas, gestionar depósitos, extender el tiempo de la subasta automáticamente ante nuevas ofertas, y procesar reembolsos y ganancias una vez finalizada la subasta.

## Contenido del Repositorio

* `4_Auction.sol`: El código fuente del contrato inteligente `Auction`.
* `README.md`: Este archivo de documentación.
* `LICENSE`: El archivo de licencia del proyecto (MIT License).

## Despliegue y Verificación

El contrato ha sido desplegado y verificado en la red de prueba Sepolia.
Puedes encontrar el contrato verificado aquí: [**[PEGAR AQUÍ LA URL DE ETHERSCAN DE TU CONTRATO VERIFICADO]**](https://sepolia.etherscan.io/address/0x6893404c5995e28c85177fc5af6c956bd8fc3389#code)

**Dirección del Contrato en Sepolia:** `0x6893404c5995e28c85177fc5af6c956bd8fc3389`

## Funcionalidades Principales (Funciones)

### Constructor

* `constructor(string memory _itemName, uint256 _auctionDuration)`
    * **Descripción:** Se ejecuta una única vez al desplegar el contrato. Inicializa la subasta con el nombre del artículo (`_itemName`) y la duración total de la subasta en segundos (`_auctionDuration`). Establece el `owner` del contrato al que lo despliega.
    * **Parámetros:**
        * `_itemName` (string): Nombre del artículo a subastar.
        * `_auctionDuration` (uint256): Duración de la subasta en segundos.
    * **Requisitos:** `_auctionDuration` debe ser mayor que 0. `_itemName` no puede estar vacío.

### Ofertar

* `placeBid() external payable auctionActive validBid`
    * **Descripción:** Permite a cualquier participante realizar una oferta por el artículo. El monto de la oferta se envía junto con la transacción (`msg.value`). Actualiza la `highestBid` y el `highestBidder`. Si la oferta se realiza en los últimos 10 minutos de la subasta, extiende su duración por 10 minutos adicionales.
    * **Modificadores:**
        * `auctionActive`: Asegura que la subasta esté activa.
        * `validBid`: Valida que la oferta sea mayor a 0 y al menos un 5% superior a la `highestBid` actual.
    * **Emite Evento:** `NewBid`

### Gestión de Fondos y Finalización

* `withdrawExcess() external auctionActive`
    * **Descripción:** Permite a un oferente retirar cualquier cantidad de Ether que haya depositado en exceso de su última oferta válida. Útil si han sido superados y no son el `highestBidder`.
    * **Modificador:** `auctionActive`
    * **Emite Evento:** `PartialWithdrawal`
* `endAuction() external onlyOwner`
    * **Descripción:** Permite al propietario del contrato finalizar la subasta manualmente, sin importar si el tiempo ha terminado o no. Una vez finalizada, no se pueden realizar más ofertas.
    * **Modificador:** `onlyOwner`
    * **Emite Evento:** `AuctionEnded`
* `processRefunds() external auctionFinished`
    * **Descripción:** Permite a los oferentes **no ganadores** reclamar el reembolso de sus depósitos una vez que la subasta ha finalizado. Se aplica una comisión del `COMMISSION_RATE` (2%) sobre el monto a reembolsar.
    * **Modificador:** `auctionFinished`
    * **Emite Evento:** `RefundProcessed`
* `withdrawWinnings() external onlyOwner auctionFinished`
    * **Descripción:** Permite al propietario del contrato retirar los fondos de la oferta ganadora una vez que la subasta ha finalizado.
    * **Modificadores:** `onlyOwner`, `auctionFinished`

### Funciones de Solo Lectura (View Functions)

* `getWinner() external view returns (address winner, uint256 winningBid)`
    * **Descripción:** Devuelve la dirección del `highestBidder` y la `highestBid` al momento de la consulta.
* `getAllBids() external view returns (Bid[] memory)`
    * **Descripción:** Devuelve un arreglo con todas las ofertas realizadas, incluyendo la dirección del oferente, el monto y la marca de tiempo.
* `getAuctionInfo() external view returns (string memory _itemName, uint256 _auctionEndTime, uint256 _highestBid, address _highestBidder, bool _auctionEnded, uint256 _totalBids)`
    * **Descripción:** Proporciona un resumen de la información clave de la subasta.
* `getTimeRemaining() external view returns (uint256)`
    * **Descripción:** Devuelve el tiempo restante para que finalice la subasta en segundos. Si ya finalizó, devuelve 0.
* `getDeposit(address bidder) external view returns (uint256)`
    * **Descripción:** Devuelve la cantidad total depositada por una dirección específica.
* `getContractBalance() external view returns (uint256)`
    * **Descripción:** Devuelve el balance actual de Ether dentro del contrato.

### Funciones Internas

* `getCurrentValidBid(address bidder) internal view returns (uint256)`
    * **Descripción:** Función auxiliar interna para determinar la oferta válida más alta de un oferente específico.

## Variables de Estado

* `owner` (address public): La dirección del propietario del contrato.
* `itemName` (string public): El nombre del artículo que se está subastando.
* `auctionEndTime` (uint256 public): La marca de tiempo (timestamp) en la que finalizará la subasta.
* `highestBid` (uint256 public): La oferta más alta actual.
* `highestBidder` (address public): La dirección del oferente que realizó la `highestBid`.
* `auctionEnded` (bool public): Un indicador booleano que es `true` si la subasta ha sido finalizada manualmente por el propietario.
* `deposits` (mapping(address => uint256) public): Un mapeo que registra el total de Ether depositado por cada dirección de oferente.
* `bids` (Bid[] public): Un arreglo de estructuras `Bid` que almacena todas las ofertas realizadas en la subasta.
* `MINIMUM_BID_INCREASE` (uint256 public constant): Constante que define el porcentaje mínimo (5%) en que una nueva oferta debe superar la oferta actual.
* `COMMISSION_RATE` (uint256 public constant): Constante que define el porcentaje de comisión (2%) que se descuenta de los reembolsos.
* `TIME_EXTENSION` (uint256 public constant): Constante que define el tiempo en segundos (10 minutos) en que se extiende la subasta si se realiza una oferta cerca del final.
* `EXTENSION_THRESHOLD` (uint256 public constant): Constante que define el umbral de tiempo (10 minutos) para activar la extensión de la subasta.

## Eventos

Los eventos se emiten para notificar a las aplicaciones externas (interfaces de usuario, servicios de monitoreo) sobre cambios importantes en el estado del contrato.

* `event NewBid(address indexed bidder, uint256 amount, uint256 timestamp)`
    * **Descripción:** Emitido cada vez que se realiza una nueva oferta válida.
    * **Parámetros:**
        * `bidder`: La dirección del oferente.
        * `amount`: El monto de la oferta.
        * `timestamp`: La marca de tiempo en que se realizó la oferta.
* `event AuctionEnded(address winner, uint256 winningBid)`
    * **Descripción:** Emitido cuando la subasta finaliza (ya sea por tiempo o por llamada a `endAuction`).
    * **Parámetros:**
        * `winner`: La dirección del oferente ganador.
        * `winningBid`: El monto de la oferta ganadora.
* `event RefundProcessed(address indexed bidder, uint256 amount)`
    * **Descripción:** Emitido cuando un oferente no ganador procesa su reembolso.
    * **Parámetros:**
        * `bidder`: La dirección del oferente que recibió el reembolso.
        * `amount`: El monto reembolsado (después de la comisión).
* `event PartialWithdrawal(address indexed bidder, uint256 amount)`
    * **Descripción:** Emitido cuando un oferente retira un exceso de sus fondos depositados.
    * **Parámetros:**
        * `bidder`: La dirección del oferente que realizó el retiro parcial.
        * `amount`: El monto retirado.

## Modificadores

Los modificadores son usados para aplicar condiciones antes de ejecutar una función.

* `onlyOwner()`: Restringe la ejecución de una función al propietario del contrato.
* `auctionActive()`: Asegura que la subasta esté aún en curso y no haya sido finalizada.
* `auctionFinished()`: Asegura que la subasta haya terminado (ya sea por tiempo o por finalización manual).
* `validBid()`: Verifica que una oferta sea válida (mayor a 0 y con el incremento mínimo requerido).

---
