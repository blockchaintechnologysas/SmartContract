// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/utils/Strings.sol"; // Importación añadida

/**
 * @title Token GRUPO EMPRESARIAL GRANACOIN S.A.S. (RWA)
 * @dev Implementación de un token ERC20 que representa acciones ordinarias certificadas
 * @notice Token de Activo del Mundo Real (RWA) con documentación legal en IPFS
 */
contract RWA_GRANACOIN is ERC20, Ownable {
    uint8 private constant _decimals = 18;
    
    // Información legal de la empresa
    string public constant RAZON_SOCIAL = "GRUPO EMPRESARIAL GRANACOIN S.A.S.";
    string public constant SIGLA = "GRANACOIN SAS";
    string public constant NIT = "901766123-3";
    string public constant DOMICILIO = "CR 24 C 51 58 CALI- VALLE";
    string public constant MATRICULA = "Matricula No: 1201961-16";
    
    // Documentación legal en IPFS
    string private _documentURI = "https://dweb.link/ipfs/Qmf1Up2NV5dNh57qyWWepp3AA3esq8uVSPm3pgwj8t1o6b";
    
    // Eventos
    event TokensMined(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event DocumentUpdated(string oldURI, string newURI);
    
    /**
     * @notice Constructor con emisión inicial y registro del documento legal
     * @param initialOwner Dirección que recibirá el suministro inicial
     */
    constructor(address initialOwner) 
        ERC20("ACCIONES GRUPO EMPRESARIAL GRANACOIN SAS", "GRA") 
    {    
        _mint(initialOwner, 100_000 * 10 ** _decimals);
    }
    
    /**
     * @dev Devuelve la URI del documento que certifica las acciones
     */
    function documentURI() public view returns (string memory) {
        return _documentURI;
    }
    
    /**
     * @dev Actualiza la URI del documento certificado
     * @param newURI Nueva ubicación del documento
     * @notice Solo el propietario puede actualizar la URI
     */
    function updateDocumentURI(string memory newURI) external onlyOwner {
        require(bytes(newURI).length > 0, "URI no puede estar vacia");
        string memory oldURI = _documentURI;
        _documentURI = newURI;
        emit DocumentUpdated(oldURI, newURI);
    }
    
    /**
     * @dev Minar nuevos tokens (solo owner)
     */
    function mineTokens(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMined(to, amount);
    }
    
    /**
     * @dev Quemar tokens del caller
     */
    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Quemar tokens de una dirección con aprobación (solo owner)
     */
    function burnTokensFrom(address from, uint256 amount) external onlyOwner {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }
    
    /**
     * @dev Información legal completa
     */
    function legalInfo() public pure returns (string memory) {
        return string(abi.encodePacked(
            "Razon Social: ", RAZON_SOCIAL, "\n",
            "Sigla: ", SIGLA, "\n",
            "NIT: ", NIT, "\n",
            "Domicilio: ", DOMICILIO, "\n",
            MATRICULA, "\n",
            "Token RWA que representa acciones ordinarias certificadas"
        ));
    }
    
    /**
     * @dev Información completa del token incluyendo documentación
     */
    function tokenInfo() external view returns (string memory) {
        return string(abi.encodePacked(
            "Nombre: ", name(), "\n",
            "Simbolo: ", symbol(), "\n",
            "Documento legal: ", _documentURI, "\n",
            "Supply total: ", Strings.toString(totalSupply() / 10 ** _decimals), "\n",
            "Decimales: ", Strings.toString(_decimals)
        ));
    }
}
