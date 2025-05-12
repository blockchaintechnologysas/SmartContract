/// @title BT&AI Token (BT&AI) - RWA de Acciones Ordinarias
/// @dev ERC20 token que representa acciones de Blockchain Technology Solutions And Artificial Intelligence AI S.A.S
/// @author BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S
/// @contact blockchaintechnologysas@gmail.com
/// @custom:whatsapp +57 3157619684
/// @website https://blockchaintechnologysas.com
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";

/**
 * @title Token BLOCKCHAIN_TECHNOLOGY
 * @dev Implementación de un token ERC20 que representa acciones ordinarias de
 * BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S (NIT 901676524-7)
 * @notice Las acciones representan unidades de participación patrimonial que otorgan
 * derechos económicos y de gobernanza sobre la empresa.
 */
contract BLOCKCHAIN_TECHNOLOGY is ERC20, Ownable {
    uint8 private constant _decimals = 18; // Decimales típicos para representación de acciones
    
    // Información legal de la empresa
    string public constant RAZON_SOCIAL = "BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S";
    string public constant SIGLA = "BLOCKCHAIN TECHNOLOGY";
    string public constant NIT = "901676524-7";
    string public constant DOMICILIO = "Calima, Valle del Cauca";
    string public constant MATRICULA = "Matricula No: 83800";
    
    /**
     * @notice Constructor que inicializa el contrato con el suministro total de acciones
     * @param initialOwner Dirección que recibirá el total de acciones (Fundación de la empresa)
     */
    constructor(address initialOwner) 
        ERC20("BLOCKCHAIN TECHNOLOGY", "BT&AI") 
    {    
        // Emisión inicial de 100,000,000,000 acciones ordinarias con voz y voto
        _mint(initialOwner, 100_000_000_000 * 10 ** _decimals);
    }
    
    /**
     * @dev Información legal completa del token
     */
    function legalInfo() public pure returns (string memory) {
        return string(abi.encodePacked(
            "Razon Social:", RAZON_SOCIAL, "\n",
            "Sigla: ", SIGLA, "\n",
            "NIT: ", NIT, "\n",
            "Domicilio: ", DOMICILIO, "\n",
            MATRICULA, "\n",
            "Las acciones representan unidades de participacion patrimonial que otorgan ",
            "a los inversores derechos economicos y de gobernanza sobre la empresa."
        ));
    }
}
