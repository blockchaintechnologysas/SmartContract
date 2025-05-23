// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.9.5/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/contracts/utils/Counters.sol";

contract LecheTrazabilidad is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    // Estructuras de datos
    struct Lote {
        string denominacionOrigen;
        uint256 cantidadLitros;
        uint256 fechaOrdeno;
        address proveedor;
    }

    struct Procesamiento {
        uint256 fechaProcesamiento;
        string planta;
        string maquinaEnvasadora;
    }

    struct Distribucion {
        string almacen;
        string transporte;
        uint256 fechaDistribucion;
    }

    struct Venta {
        address comprador;
        uint256 fechaCompra;
        uint256 precioPagado;
    }

    // Mapeos
    mapping(uint256 => Lote) public lotes; // LoteId => Datos
    mapping(uint256 => Procesamiento) public procesamientos; // NFTId => Datos
    mapping(uint256 => Distribucion) public distribuciones; // NFTId => Datos
    mapping(uint256 => Venta) public ventas; // NFTId => Datos
    mapping(address => uint256[]) public nftsPorWallet; // Wallet => NFTIds

    // Tokens
    IERC20 public tokenPago; // Token ERC-20 para comprar NFTs
    uint256 public precioPorLitro; // Precio en tokens ERC-20

    // Contadores
    Counters.Counter private _loteIdCounter;
    Counters.Counter private _nftIdCounter;

    // Eventos
    event LoteCreado(uint256 loteId, string nombreLote);
    event NFTProcesado(uint256 nftId, uint256 loteId);
    event NFTVendido(uint256 nftId, address comprador);

    constructor(address _tokenPago, uint256 _precioEnTokens) 
        ERC721("LecheTrazabilidadNFT", "LTN") {
        tokenPago = IERC20(_tokenPago);
        precioPorLitro = _precioEnTokens * 10**18; // Convertir a unidades base (wei)
    }

    // Función 1: Registrar Lote (Denominación de Origen)
    function p1_registrarLote(
        string memory _nombreLote,
        string memory _denominacionOrigen,
        uint256 _cantidadLitros,
        uint256 _fechaOrdeno,
        address _proveedor
    ) external onlyOwner {
        uint256 loteId = _loteIdCounter.current();
        lotes[loteId] = Lote({
            denominacionOrigen: _denominacionOrigen,
            cantidadLitros: _cantidadLitros,
            fechaOrdeno: _fechaOrdeno,
            proveedor: _proveedor
        });
        _loteIdCounter.increment();
        emit LoteCreado(loteId, _nombreLote);
    }

    // Función 2: Procesamiento Industrial (Minting de NFTs)
    function p2_procesarNFTs(
        uint256 _loteId,
        string memory _planta,
        string memory _maquinaEnvasadora,
        uint256 _cantidad
    ) external onlyOwner {
        require(_cantidad <= lotes[_loteId].cantidadLitros, "Excede litros del lote");
        
        for (uint256 i = 0; i < _cantidad; i++) {
            uint256 nftId = _nftIdCounter.current();
            _safeMint(address(this), nftId); // Mintea a la dirección del contrato
            procesamientos[nftId] = Procesamiento({
                fechaProcesamiento: block.timestamp,
                planta: _planta,
                maquinaEnvasadora: _maquinaEnvasadora
            });
            _nftIdCounter.increment();
            emit NFTProcesado(nftId, _loteId);
        }
    }

    // Función 3: Almacenamiento/Distribución
    function p3_registrarDistribucion(
        uint256 _nftId,
        string memory _almacen,
        string memory _transporte
    ) external onlyOwner {
        distribuciones[_nftId] = Distribucion({
            almacen: _almacen,
            transporte: _transporte,
            fechaDistribucion: block.timestamp
        });
    }

    // Función 4: Venta al Punto de Venta (Compra con Token ERC-20)
    function p4_comprarNFT(uint256 _nftId) external {
        require(ownerOf(_nftId) == address(this), "NFT no disponible");
        tokenPago.transferFrom(msg.sender, owner(), precioPorLitro);
        _transfer(address(this), msg.sender, _nftId);
        
        ventas[_nftId] = Venta({
            comprador: msg.sender,
            fechaCompra: block.timestamp,
            precioPagado: precioPorLitro
        });
        nftsPorWallet[msg.sender].push(_nftId);
        emit NFTVendido(_nftId, msg.sender);
    }

    // Función 5: Consulta de Trazabilidad por NFT
    function p5_consultarTrazabilidad(uint256 _nftId) external view returns (
        Lote memory lote,
        Procesamiento memory procesamiento,
        Distribucion memory distribucion,
        Venta memory venta
    ) {
        uint256 loteId = _nftId / 1e6; // Ejemplo: NFT 1 pertenece al Lote 0
        return (
            lotes[loteId],
            procesamientos[_nftId],
            distribuciones[_nftId],
            ventas[_nftId]
        );
    }

    // Función 6: NFTs comprados por Wallet
    function nftsDeUsuario(address _wallet) external view returns (uint256[] memory) {
        return nftsPorWallet[_wallet];
    }
}
