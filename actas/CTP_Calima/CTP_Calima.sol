// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importación de contratos de OpenZeppelin
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/utils/structs/EnumerableSet.sol";

// Contrato principal para gestionar VPS autorizadas
contract AuthorizedVPS is Ownable {
    // Uso de la librería EnumerableSet para conjuntos de direcciones
    using EnumerableSet for EnumerableSet.AddressSet;

    // Conjunto de direcciones de VPS autorizadas
    EnumerableSet.AddressSet private authorizedVPS;

    // Evento emitido cuando se autoriza o desautoriza una VPS
    event VPSAuthorized(address indexed vps, bool status);

    // Modificador para restringir el acceso a las funciones solo a VPS autorizadas
    modifier onlyAuthorizedVPS() {
        require(isVPSAuthorized(msg.sender), "VPS no autorizada");
        _;
    }

    // Constructor del contrato
    constructor() {}

    // Función para verificar si una VPS está autorizada
    function isVPSAuthorized(address _vps) public view returns (bool) {
        return authorizedVPS.contains(_vps);
    }

    // Función para autorizar una VPS
    function authorizeVPS(address _vps) external onlyOwner {
        require(!isVPSAuthorized(_vps), "La VPS ya esta autorizada");
        authorizedVPS.add(_vps);
        emit VPSAuthorized(_vps, true);
    }

    // Función para desautorizar una VPS
    function deauthorizeVPS(address _vps) external onlyOwner {
        require(isVPSAuthorized(_vps), "La VPS no esta autorizada");
        authorizedVPS.remove(_vps);
        emit VPSAuthorized(_vps, false);
    }

    // Función para obtener la cantidad de VPS autorizadas
    function authorizedVPSCount() external view returns (uint256) {
        return authorizedVPS.length();
    }

    // Función para obtener la dirección de una VPS autorizada por su índice
    function getAuthorizedVPS(uint256 index) external view returns (address) {
        require(index < authorizedVPS.length(), "El indice esta fuera de rango");
        return authorizedVPS.at(index);
    }
}

// Contrato principal para gestionar actas CTP Calima
contract CTP_Calima is AuthorizedVPS {
    struct Acta {
        uint256 acta;
        string fecha;
        string hora;
        string lugar;
        string ciudad;
        string presidente;
        string secretario;
        string URI;
        address wallet;
    }

    mapping(uint256 => Acta) public actas;
    uint256 public totalActas;

    event ActaIngresada(uint256 indexed acta, string fecha, string lugar, address indexed wallet);

    function ingresarActa(uint256 _acta, string memory _fecha, string memory _hora, string memory _lugar, string memory _ciudad, string memory _presidente, string memory _secretario, string memory _URI) public onlyAuthorizedVPS {
        require(actas[_acta].acta == 0, "Esta acta ya existe");
        actas[_acta] = Acta(_acta, _fecha, _hora, _lugar, _ciudad, _presidente, _secretario, _URI, msg.sender);
        totalActas++;
        emit ActaIngresada(_acta, _fecha, _lugar, msg.sender);
    }
}

