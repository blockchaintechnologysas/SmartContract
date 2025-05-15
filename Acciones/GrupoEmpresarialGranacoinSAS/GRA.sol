// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";

/**
 * @title Token GRUPO EMPRESARIAL GRANACOIN S.A.S.
 * @dev Implementación de un token ERC20 que representa acciones ordinarias de
 * BLOCKCHAIN TECHNOLOGY SOLUTIONS AND ARTIFICIAL INTELLIGENCE AI S.A.S (NIT 901676524-7)
 * @notice Las acciones representan unidades de participación patrimonial que otorgan
 * derechos económicos y de gobernanza sobre la empresa.
 */
contract RWA_GRANACOIN is ERC20, Ownable {
    uint8 private constant _decimals = 18; // Decimales típicos para representación de acciones
    
    // Información legal de la empresa
    string public constant RAZON_SOCIAL = "GRUPO EMPRESARIAL GRANACOIN S.A.S.";
    string public constant SIGLA = "GRANACOIN SAS";
    string public constant NIT = "901766123-3";
    string public constant DOMICILIO = "CR 24 C 51 58";
    string public constant MATRICULA = "Matricula No: 1201961-16";
    
    // Eventos para minado y quema de tokens
    event TokensMined(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    
    /**
     * @notice Constructor que inicializa el contrato con el suministro inicial de acciones
     * @param initialOwner Dirección que recibirá el total de acciones (Fundación de la empresa)
     */
    constructor(address initialOwner) 
        ERC20("ACCIONES GRUPO EMPRESARIAL GRANACOIN SAS", "GRA") 
    {    
        // Emisión inicial de 100,000 acciones ordinarias con voz y voto
        _mint(initialOwner, 100_000 * 10 ** _decimals);
    }
    
    /**
     * @dev Función para minar (crear) nuevos tokens
     * @param to Dirección que recibirá los nuevos tokens
     * @param amount Cantidad de tokens a minar
     * @notice Solo el propietario del contrato puede minar nuevos tokens
     */
    function mineTokens(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMined(to, amount);
    }
    
    /**
     * @dev Función para quemar (destruir) tokens
     * @param amount Cantidad de tokens a quemar
     * @notice Cualquier titular de tokens puede quemar sus propios tokens
     */
    function burnTokens(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Función para quemar tokens desde una dirección específica (requiere aprobación previa)
     * @param from Dirección desde la que se quemarán los tokens
     * @param amount Cantidad de tokens a quemar
     * @notice Solo el propietario del contrato puede quemar tokens de otras direcciones
     */
    function burnTokensFrom(address from, uint256 amount) external onlyOwner {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit TokensBurned(from, amount);
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
