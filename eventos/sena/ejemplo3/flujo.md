## 🔄 Flujo de Uso del Smart Contract

### 1. **Empresa Láctea**  
```solidity
// Paso 1: Registrar un nuevo lote de leche
registrarLote(
    "LT-20240514",       // Nombre del lote
    "Jamundi",         // Denominación de origen
    5000,                // Cantidad de litros (NFTs)
    1652544000,          // Fecha de ordeño (timestamp)
    0xProveedor...       // Address del proveedor
);

// Paso 2: Procesar y mintear NFTs
procesarNFTs(
    0,                   // ID del lote
    "Planta N°2",        // Planta de procesamiento
    "E-45",              // Máquina envasadora
    5000                 // Cantidad de NFTs a mintear
);

// Paso 3: Registrar distribución del NFT #123
registrarDistribucion(
    123,                 // ID del NFT
    "Almacén Central",   // Centro de almacenamiento
    "REF-789"            // Transporte utilizado
);

// Paso 4: Compra del NFT #123 (pago con tokens ERC-20)
comprarNFT(123);        // Transfiere tokens y recibe el NFT

// Paso 5: Escanear QR y consultar datos del NFT #123
consultarTrazabilidad(123);
