// ACC.sol
/// @title ACCOLOMBIA 4.0 SAS Token (ACC40) - RWA de Acciones Ordinarias
/// @dev ERC20 token que representa acciones de ACCOLOMBIA 4.0 S.A.S
/// @author BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S
/// @contact gerencia@accolombia.com
/// @custom:whatsapp +57 3157619684
/// @website https://accolombia.com
/// @Address: 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";

/**
 * @title Token ACCOLOMBIA 4.0 SAS
 * @dev Implementación de un token ERC20 que representa acciones ordinarias de
 * BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S (NIT 901676524-7)
 * @notice Las acciones representan unidades de participación patrimonial que otorgan
 * derechos económicos y de gobernanza sobre la empresa.
 */
contract ACCOLOMBIA is ERC20, Ownable {
    uint8 private constant _decimals = 18; // Decimales típicos para representación de acciones
    
    // Información legal de la empresa
    string public constant RAZON_SOCIAL = "ACCOLOMBIA 4.0 SAS";
    string public constant SIGLA = "BLOCKCHAIN";
    string public constant NIT = "901366479-3";
    string public constant DOMICILIO = "Calima, Valle del Cauca";
    string public constant MATRICULA = "Matricula No: 83748";
    
    /**
     * @notice Constructor que inicializa el contrato con el suministro total de acciones
     * @param initialOwner Dirección que recibirá el total de acciones (Fundación de la empresa)
     */
    constructor(address initialOwner) 
        ERC20("ACCOLOMBIA 4.0 SAS", "ACC40") 
    {    
        // Emisión inicial de 20,000,000 acciones ordinarias con voz y voto
        _mint(initialOwner, 20_000_000 * 10 ** _decimals);
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
