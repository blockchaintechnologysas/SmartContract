Direccion: https://explorer.scolcoin.com/address/0x45D32551890263bA67a64fC97Fc9688224eaCb99/transactions

# Municipio Calima Darien - Primer Consejo Territorial (CTP) Municipal con Almacenamiento de Actas en Blockchain

¡Bienvenidos al Consejo Territorial del Municipio Calima Darien, donde la transparencia y la eficiencia se unen a través de la tecnología Blockchain!

## Descripción

El Consejo Territorial es un espacio de participación ciudadana donde se toman decisiones cruciales para el desarrollo local y la mejora de la calidad de vida de sus habitantes. En este contexto, el Municipio Calima Darien ha marcado un hito histórico al convertirse en el primer municipio en implementar la tecnología Blockchain para almacenar y consultar públicamente sus Actas.

## ¿Qué hace este CTP especial?

Este Consejo Territorial marca la diferencia al adoptar tecnología de vanguardia para asegurar la transparencia y accesibilidad de sus procesos. A través de un Contrato Inteligente (Smart Contract) basado en la tecnología Blockchain, todas las Actas se almacenan de manera segura y descentralizada, garantizando su integridad y evitando alteraciones. Además, cualquier persona puede consultarlas en tiempo real desde nuestro portal web oficial.

## Acceso a las Actas

Para acceder a las Actas del Consejo Territorial, simplemente visita nuestro [Github](https://github.com/blockchaintechnologysas/SmartContract/blob/main/actas/CTP_Calima/README.md) y encuentra un enlace directo al registro de Actas del CTP. Desde cualquier dispositivo con conexión a internet, podrás verificar la transpariencia a la información de manera rápida.

## Participa

Te invitamos a formar parte de este emocionante avance hacia la transparencia y la participación ciudadana. Sé parte del cambio en el Municipio Calima Darien, Valle del Cauca. Descubre un nuevo estándar de gobierno abierto y participativo del Alcalde Municipal Alejandro Cadavid Pinilla, respaldado por la tecnología Blockchain.

## Repositorio en GitHub

Para más detalles sobre la implementación del Contrato Inteligente (Smart Contract) y el código utilizado, visita nuestro repositorio en GitHub: [CTP_Calima - Blockchain Actas](https://github.com/blockchaintechnologysas/SmartContract/tree/main/actas/CTP_Calima)

Explorador: https://explorer.scolcoin.com/address/0x45D32551890263bA67a64fC97Fc9688224eaCb99/read-contract 

# Documento Tecnico contrato AuthorizedVPS y CTP_Calima:

### Contract AuthorizedVPS
Este contrato permite la gestión de VPS (Servidores Privados Virtuales) autorizadas para interactuar con el sistema.

### Modificadores
onlyAuthorizedVPS: Restringe el acceso a ciertas funciones solo a las VPS autorizadas.

### Eventos

VPSAuthorized: Emitido cuando se autoriza o desautoriza una VPS. Contiene la dirección de la VPS y su estado de autorización.
### Funciones

* isVPSAuthorized(address _vps): Verifica si una dirección de VPS está autorizada.
* authorizeVPS(address _vps): Autoriza una nueva dirección de VPS. Solo puede ser llamada por el propietario del contrato.
* deauthorizeVPS(address _vps): Desautoriza una dirección de VPS. Solo puede ser llamada por el propietario del contrato.
* authorizedVPSCount(): Obtiene la cantidad de VPS autorizadas.
* getAuthorizedVPS(uint256 index): Obtiene la dirección de una VPS autorizada por su índice.

# Contract CTP_Calima
Este contrato permite la gestión de actas CTP Calima, con restricciones de acceso para garantizar que solo las VPS autorizadas puedan ingresar actas.

# Structs
Acta: Estructura de datos que representa una acta CTP Calima.

# Eventos
ActaIngresada: Emitido cuando se ingresa una nueva acta. Contiene el número de acta, la fecha, el lugar y la dirección del remitente.

# Funciones
ingresarActa(uint256 _acta, string memory _fecha, string memory _hora, string memory _lugar, string memory _ciudad, string memory _presidente, string memory _secretario, string memory _URI): Permite ingresar una nueva acta CTP Calima. Solo puede ser llamada por las VPS autorizadas.
