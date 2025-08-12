// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.5/token/ERC721/IERC721.sol";

/// @title Trazabilidad de Restaurante - Etapa 2 (sin NFT nuevo, sin tienda)
/// @notice Registra la elaboración y servicio de platos a partir de ingredientes trazados (p.ej. Tomate NFT).
contract TomatoStage2Trace is Ownable {
    // (Opcional) Referencias a contratos existentes para verificación cruzada
    IERC721 public immutable tomatoNFT;     // contrato ERC-721 del Tomate (ya desplegado)
    address public immutable tomatoTrace;   // contrato TomatoTrace (etapa 1), solo para referencia off-chain

    constructor(address _tomatoNFT, address _tomatoTrace) {
        tomatoNFT = IERC721(_tomatoNFT);
        tomatoTrace = _tomatoTrace;
    }

    // ----- Roles operativos (planta/restaurante) -----
    mapping(address => bool) public isOperator;
    event OperatorSet(address operator, bool allowed);

    modifier onlyOperator() {
        require(isOperator[msg.sender] || msg.sender == owner(), "not operator");
        _;
    }

    function setOperator(address op, bool allowed) external onlyOwner {
        isOperator[op] = allowed;
        emit OperatorSet(op, allowed);
    }

    // ============= Datos de la Etapa 2 =============
    struct DatosProducto {
        // Encabezado del plato/lote interno
        string productoFinal;      // "Crema de Tomate (Entrada)"
        string restaurante;        // "Sabores del Valle"
        string loteInternoPlato;   // "CT-20240812-EN"
        string fechaElaboracion;   // "12/08/2024"
    }

    struct OrigenIngrediente {
        // Origen del Tomate (ingrediente principal) + vínculo opcional al NFT
        string ingrediente;         // "Tomate Chonto (1 lb)"
        string proveedor;           // "Frescampo Sucursal Centro (Buga)."
        string loteTomate;          // "TC-20240810 (AgroTrace SAS)."
        string procedencia;         // "Finca 'El Amanecer', Buga, Valle del Cauca."
        string fechaCosecha;        // "09/08/2024"
        string fechaCompra;         // "11/08/2024"
        string transporte;          // "Vehículo refrigerado 10°C"
        address nft;                // dirección del NFT del tomate (opcional; normalmente = tomatoNFT)
        uint256 tokenId;            // tokenId del tomate utilizado (opcional)
    }

    struct Recepcion {
        string inspeccionVisual;    // "Color uniforme, sin daños mecánicos."
        string pesoRecibido;        // "1 libra exacta (0,45 kg)."
        string almacenamientoTemp;  // "Cámara refrigerada a 8°C."
        string fechaRecepcion;      // (opcional) "11/08/2024"
    }

    struct Elaboracion {
        string fechaPreparacion;    // "12/08/2024 (9:00 am)"
        string cocinaResponsable;   // "Cocina Principal – Chef encargado: María Gómez"
        string recetaBase;          // pasos resumidos
        string loteInterno;         // "CT-20240812-EN"
        string equipoUtilizado;     // "Olla industrial #OI-22, licuadora #BL-05"
    }

    struct Servicio {
        string fechaHoraServicio;   // "12/08/2024 – 1:15 pm"
        string mesa;                // "#12"
        string pedido;              // "Solicitud directa del menú como entrada"
        string condiciones;         // "Servida caliente (65°C), con pan artesanal"
    }

    struct Documentos {
        string facturaCompraTomate;     // "Frescampo → Restaurante Sabores del Valle"
        string registroTrazabilidad;    // "Lote TC-20240810"
        string hojaProduccionInterna;   // "Lote CT-20240812-EN"
        string controlBPM;              // "Registro diario de limpieza y temperatura"
        string comandaCliente;          // "Orden #A-215"
    }

    // ID interno incremental del registro de plato (no es un NFT)
    uint256 private _regId;
    mapping(uint256 => bool) public exists;

    // regId => structs
    mapping(uint256 => DatosProducto)   public datosProducto;
    mapping(uint256 => OrigenIngrediente) public origen;
    mapping(uint256 => Recepcion)       public recepcion;
    mapping(uint256 => Elaboracion)     public elaboracion;
    mapping(uint256 => Servicio)        public servicio;
    mapping(uint256 => Documentos)      public documentos;

    // ====== Eventos ======
    event RegistroCreado(uint256 indexed regId, string loteInternoPlato, string productoFinal);
    event OrigenSet(uint256 indexed regId);
    event RecepcionSet(uint256 indexed regId);
    event ElaboracionSet(uint256 indexed regId);
    event ServicioSet(uint256 indexed regId);
    event DocumentosSet(uint256 indexed regId);

    // ====== Helpers ======
    function _nftExists(address nftAddr, uint256 tokenId) internal view returns (bool) {
        if (nftAddr == address(0)) return true; // opcional: permitir sin NFT
        try IERC721(nftAddr).ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    // ============= Flujo de carga =============

    /// @notice Crea un registro vacío con datos del plato (cabecera). Devuelve el regId.
    function crearRegistro(DatosProducto calldata d) external onlyOperator returns (uint256 regId) {
        regId = _regId;
        _regId += 1;
        exists[regId] = true;
        datosProducto[regId] = d;
        emit RegistroCreado(regId, d.loteInternoPlato, d.productoFinal);
    }

    /// @notice 1) Origen del ingrediente principal (Tomate).
    function setOrigen(uint256 regId, OrigenIngrediente calldata o) external onlyOperator {
        require(exists[regId], "reg !exist");
        // (opcional) si pasan token, verifica que exista
        require(_nftExists(o.nft, o.tokenId), "tomato NFT !exist");
        origen[regId] = o;
        emit OrigenSet(regId);
    }

    /// @notice 2) Recepción en restaurante (control de calidad).
    function setRecepcion(uint256 regId, Recepcion calldata r) external onlyOperator {
        require(exists[regId], "reg !exist");
        recepcion[regId] = r;
        emit RecepcionSet(regId);
    }

    /// @notice 3) Proceso de elaboración culinaria.
    function setElaboracion(uint256 regId, Elaboracion calldata e) external onlyOperator {
        require(exists[regId], "reg !exist");
        elaboracion[regId] = e;
        emit ElaboracionSet(regId);
    }

    /// @notice 4) Servicio al cliente.
    function setServicio(uint256 regId, Servicio calldata s) external onlyOperator {
        require(exists[regId], "reg !exist");
        servicio[regId] = s;
        emit ServicioSet(regId);
    }

    /// @notice 5) Documentos clave de esta etapa.
    function setDocumentos(uint256 regId, Documentos calldata d) external onlyOperator {
        require(exists[regId], "reg !exist");
        documentos[regId] = d;
        emit DocumentosSet(regId);
    }

    /// @notice Vista agrupada de todo el registro.
    function verRegistro(uint256 regId) external view returns (
        DatosProducto memory,
        OrigenIngrediente memory,
        Recepcion memory,
        Elaboracion memory,
        Servicio memory,
        Documentos memory
    ) {
        require(exists[regId], "reg !exist");
        return (
            datosProducto[regId],
            origen[regId],
            recepcion[regId],
            elaboracion[regId],
            servicio[regId],
            documentos[regId]
        );
    }

    /// @notice Devuelve el siguiente ID que se asignaría (para UI).
    function nextRegId() external view returns (uint256) {
        return _regId;
    }
}
