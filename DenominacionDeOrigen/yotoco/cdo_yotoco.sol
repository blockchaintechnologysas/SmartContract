// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importación de contratos de OpenZeppelin para la gestión de permisos
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol";

// Importación de la librería EnumerableSet para conjuntos de direcciones
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title DenominacionDeOrigen
 * @dev Contrato para la gestión de Denominaciones de Origen (CDO)
 */
contract DenominacionDeOrigen is Ownable {
    // Usamos la librería EnumerableSet para conjuntos de direcciones
    using EnumerableSet for EnumerableSet.AddressSet;

    // Estructura para los datos de la Denominación de Origen (CDO)
    struct CDO {
        uint256 id;                 // Identificador único de la CDO
        string fecha;               // Fecha de registro
        string hora;                // Hora de registro
        string producto;            // Producto asociado a la CDO
        string razonsocial;         // Razón social asociada a la CDO
        string identificacion;      // Identificación asociada a la CDO
        string ciudad;              // Ciudad asociada a la CDO
        string pais;                // País asociado a la CDO
        string URI;                 // URI relacionada con la CDO
        address usuario;            // Dirección del usuario relacionado a la CDO
        address wallet;             // Dirección de la billetera relacionada a la CDO
        bool status;                // Estado de la CDO (activo/inactivo)
        string arancelario;         // Código arancelario asociado a la CDO
    }

    // Conjunto de direcciones de VPS autorizados
    EnumerableSet.AddressSet private authorizedVPS;

    // Conjunto de datos de Denominaciones de Origen (CDOs)
    mapping(uint256 => CDO) public CDOs;
    uint256 public totalCDOs;   // Total de CDOs registradas

    // Evento emitido cuando se registra una nueva Denominación de Origen (CDO)
    event CDORegistrada(uint256 indexed id, string fecha, string producto, address indexed usuario);

    // Evento emitido cuando el estado de una Denominación de Origen (CDO) es modificado
    event StatusModificado(uint256 indexed id, bool nuevoStatus);

    // Modificador para restringir el acceso a las funciones solo a VPS autorizados
    modifier onlyAuthorizedVPS() {
        require(authorizedVPS.contains(msg.sender), "VPS no autorizado");
        _;
    }

    // Función para verificar si una dirección está autorizada como VPS
    function isVPSAuthorized(address _vps) public view returns (bool) {
        return authorizedVPS.contains(_vps);
    }

    // Función para autorizar un VPS (solo el propietario puede llamar a esta función)
    function authorizeVPS(address _vps) external onlyOwner {
        require(!isVPSAuthorized(_vps), "VPS ya autorizado");
        authorizedVPS.add(_vps);
    }

    // Función para almacenar datos en la estructura CDO (solo VPS autorizados pueden llamar a esta función)
    function almacenarCDO(
        uint256 _id,
        string memory _fecha,
        string memory _hora,
        string memory _producto,
        string memory _razonsocial,
        string memory _identificacion,
        string memory _ciudad,
        string memory _pais,
        string memory _URI,
        address _usuario,
        address _wallet,
        string memory _arancelario
    ) external onlyAuthorizedVPS {
        require(CDOs[_id].id == 0, "ID de CDO ya existe");
        CDO memory nuevaCDO;
        nuevaCDO.id = _id;
        nuevaCDO.fecha = _fecha;
        nuevaCDO.hora = _hora;
        nuevaCDO.producto = _producto;
        nuevaCDO.razonsocial = _razonsocial;
        nuevaCDO.identificacion = _identificacion;
        nuevaCDO.ciudad = _ciudad;
        nuevaCDO.pais = _pais;
        nuevaCDO.URI = _URI;
        nuevaCDO.usuario = _usuario;
        nuevaCDO.wallet = _wallet;
        nuevaCDO.status = true; // Por defecto, establecemos el estado en true al almacenar
        nuevaCDO.arancelario = _arancelario;
        CDOs[_id] = nuevaCDO;
        totalCDOs++;
        emit CDORegistrada(_id, _fecha, _producto, _usuario);
    }

    // Función para obtener el estado de una Denominación de Origen por su ID
    function obtenerStatusCDO(uint256 _id) external view returns (bool) {
        require(CDOs[_id].id != 0, "Denominacion de Origen no encontrada");
        return CDOs[_id].status;
    }

    // Función para modificar el estado de una Denominación de Origen (solo VPS autorizados pueden llamar a esta función)
    function modificarStatusCDO(uint256 _id, bool _nuevoStatus) external onlyAuthorizedVPS {
        require(CDOs[_id].id != 0, "Denominacion de Origen no encontrada");
        CDOs[_id].status = _nuevoStatus;
        emit StatusModificado(_id, _nuevoStatus);
    }
}
