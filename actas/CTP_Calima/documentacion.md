# contrato AuthorizedVPS y CTP_Calima:

### Contract AuthorizedVPS
Este contrato permite la gestión de VPS (Servidores Privados Virtuales) autorizadas para interactuar con el sistema.

### Modificadores

onlyAuthorizedVPS: Restringe el acceso a ciertas funciones solo a las VPS autorizadas.
### Eventos

VPSAuthorized: Emitido cuando se autoriza o desautoriza una VPS. Contiene la dirección de la VPS y su estado de autorización.
### Funciones

- isVPSAuthorized(address _vps): Verifica si una dirección de VPS está autorizada.
- authorizeVPS(address _vps): Autoriza una nueva dirección de VPS. Solo puede ser llamada por el propietario del contrato.
- deauthorizeVPS(address _vps): Desautoriza una dirección de VPS. Solo puede ser llamada por el propietario del contrato.
- authorizedVPSCount(): Obtiene la cantidad de VPS autorizadas.
- getAuthorizedVPS(uint256 index): Obtiene la dirección de una VPS autorizada por su índice.

# Contract CTP_Calima
Este contrato permite la gestión de actas CTP Calima, con restricciones de acceso para garantizar que solo las VPS autorizadas puedan ingresar actas.

Structs
Acta: Estructura de datos que representa una acta CTP Calima.
Eventos
ActaIngresada: Emitido cuando se ingresa una nueva acta. Contiene el número de acta, la fecha, el lugar y la dirección del remitente.
Funciones
ingresarActa(uint256 _acta, string memory _fecha, string memory _hora, string memory _lugar, string memory _ciudad, string memory _presidente, string memory _secretario, string memory _URI): Permite ingresar una nueva acta CTP Calima. Solo puede ser llamada por las VPS autorizadas.
