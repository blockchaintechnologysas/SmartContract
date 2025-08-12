// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/IERC721.sol";

contract TomatoTrace is Ownable {
    IERC721 public immutable nft;

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
    }

    struct Lote {
        string empresa;
        string producto;
        string codigoLote;
        string fechaEnvasado;
        string proveedor;
        string ubicacion;
        string fechaCosecha;
        string cantidadKg;
        string calibre;
        string color;
        string observaciones;
    }

    struct Procesamiento {
        string planta;
        string proceso;
        string maquina;
        string horaEmpaque;
        string fechaRegistro;
    }

    struct Distribucion {
        string almacen;
        string transporte;
        string destino;
        string fechaEntrega;
    }

    struct PuntoDeVenta {
        string supermercado;
        string codigoBarras;
        string fechaCaducidad;
    }

    struct Venta {
        string cliente;
        string fechaCompra;
        string canal;
        string precio;
    }

    struct Documentos {
        string registroCosecha;
        string certificadoResiduos;
        string reporteProduccion;
        string hojaRuta;
        string factura;
        string normas;
    }

    // tokenId => data
    mapping(uint256 => Lote) public lotes;
    mapping(uint256 => Procesamiento) public procesos;
    mapping(uint256 => Distribucion) public distribuciones;
    mapping(uint256 => PuntoDeVenta) public puntosVenta;
    mapping(uint256 => Venta) public ventas;
    mapping(uint256 => Documentos) public documentos;

    event SetLote(uint256 indexed tokenId);
    event SetProc(uint256 indexed tokenId);
    event SetDist(uint256 indexed tokenId);
    event SetPDV(uint256 indexed tokenId);
    event SetVenta(uint256 indexed tokenId);
    event SetDocs(uint256 indexed tokenId);

    // Opcional: autorizar cuentas (operadores) que pueden cargar datos (p.ej. planta, almacén, mercado)
    mapping(address => bool) public isOperator;
    event OperatorSet(address operator, bool allowed);

    modifier onlyOperator() {
        require(isOperator[msg.sender] || owner() == msg.sender, "no operator");
        _;
    }

    function setOperator(address op, bool allowed) external onlyOwner {
        isOperator[op] = allowed;
        emit OperatorSet(op, allowed);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        // ownerOf revierte si no existe
        try nft.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    // ——— setters ———
    function setLote(uint256 tokenId, Lote calldata d) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        lotes[tokenId] = d;
        emit SetLote(tokenId);
    }

    function setProcesamiento(uint256 tokenId, Procesamiento calldata p) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        procesos[tokenId] = p;
        emit SetProc(tokenId);
    }

    function setDistribucion(uint256 tokenId, Distribucion calldata d) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        distribuciones[tokenId] = d;
        emit SetDist(tokenId);
    }

    function setPuntoDeVenta(uint256 tokenId, PuntoDeVenta calldata v) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        puntosVenta[tokenId] = v;
        emit SetPDV(tokenId);
    }

    function setVenta(uint256 tokenId, Venta calldata v) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        ventas[tokenId] = v;
        emit SetVenta(tokenId);
    }

    function setDocumentos(uint256 tokenId, Documentos calldata docu) external onlyOperator {
        require(_exists(tokenId), "token !exist");
        documentos[tokenId] = docu;
        emit SetDocs(tokenId);
    }

    // Vista agrupada
    function ver(uint256 tokenId) external view returns (
        Lote memory, Procesamiento memory, Distribucion memory,
        PuntoDeVenta memory, Venta memory, Documentos memory
    ) {
        require(_exists(tokenId), "token !exist");
        return (
            lotes[tokenId],
            procesos[tokenId],
            distribuciones[tokenId],
            puntosVenta[tokenId],
            ventas[tokenId],
            documentos[tokenId]
        );
    }
}
