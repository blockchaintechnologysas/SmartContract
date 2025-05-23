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
