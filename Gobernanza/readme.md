# Gobernanza Corporativa en Blockchain

## Características Principales del Sistema

### 1. Libro de Accionistas Digital (BTAI_ShareRegistry)
- **Registro histórico completo**: Todas las transferencias quedan registradas con fecha y observaciones
- **Mecanismo de sucesión**: Función especial para transferencias por fallecimiento con verificación legal
- **Consulta de accionistas**: Listado completo de accionistas activos con sus balances
- **Sistema decimal adecuado**: 2 decimales para representación precisa de acciones

### 2. Sistema de Gobernanza DAO (BTAI_DAO)
- **Tres tipos de propuestas**:
  - Económicas: Para movimientos de fondos (USDT, BTC, etc.)
  - Escritas: Para decisiones estratégicas
  - Elecciones: Para cargos directivos (cada 2 años)
  
- **Votación ponderada**:
  - Cada acción = 1 voto
  - Quórum del 51% para decisiones económicas/escritas
  - Mayoría simple para elecciones
  
- **Restricciones de creación**:
  - Solo los 10 mayores accionistas pueden crear propuestas
  - Todos los accionistas pueden votar

### 3. Junta Directiva Electa
- **Cargos principales**: Presidente, Vicepresidente, Secretario, Fiscal, Tesorero y CEO
- **Términos de 2 años**: Con fechas exactas de inicio/fin
- **Proceso electoral**: Iniciado por los mayores accionistas

### 4. Seguridad y Transparencia
- **Registro inmutable**: Todos los movimientos quedan en blockchain
- **Verificación legal**: Mecanismos para sucesiones y cambios importantes
- **Acceso público**: Cualquiera puede verificar el estado accionario

### 5. Función de Migración (BTAI_Migration)
- **Acceso Controlado**:
  - Solo el owner puede ejecutar la migración
  - El contrato se marca como inactivo después de la migración
  
- **Proceso Completo**:
  - Recoge todos los tokens de todos los accionistas
  - Los transfiere al dueño del contrato
  - Opcionalmente los puede enviar directamente a un nuevo contrato
  
- **Registro Detallado**:
  - Cada transferencia queda registrada en el historial
  - Evento especial `ContractMigrated` con todos los detalles
  
- **Seguridad**:
  - Todas las funciones de transferencia se desactivan después de la migración
  - Modificador `onlyActive` protege las funciones clave
  
- **Transparencia**:
  - Los accionistas pueden verificar el estado de migración
  - Todo el historial de transferencias permanece accesible
