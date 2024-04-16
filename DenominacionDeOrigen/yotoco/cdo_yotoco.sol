// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importación de contratos de OpenZeppelin
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/structs/EnumerableSet.sol";

contract DenominacionDeOrigen is Ownable {
    // Usamos la librería EnumerableSet para conjuntos de direcciones
    using EnumerableSet for EnumerableSet.AddressSet;

    // Estructura para los datos de la Denominación de Origen
    struct CDO {
        uint256 id;
        string fecha;
        string hora;
        string producto;
        string razonsocial;
        string identificacion;
        string ciudad;
        string pais;
        string URI;
        address usuario; //wallet usuario mas datos
        address wallet;
        bool status;        //estado del certificado
        string arancelario; // codigo arancelario
    }

    // Conjunto de direcciones de VPS autorizados
    EnumerableSet.AddressSet private authorizedVPS;

    // Conjunto de datos de Denominaciones de Origen
    mapping(uint256 => CDO) public CDOs;
    uint256 public totalCDOs;

    // Evento emitido cuando se registra una nueva Denominación de Origen
    event CDORegistrada(uint256 indexed id, string fecha, string producto, address indexed usuario);
    // Evento emitido cuando el status de una Denominación de Origen es modificado
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

    // Función para autorizar un VPS (solo el dueño puede llamar a esta función)
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
