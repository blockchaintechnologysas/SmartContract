# Este documento muestra como esta construido

### 3 contratos para bajar el tamaño y dejar cada rol claro:
- TomatoNFT → sólo acuña y administra el ERC-721 (1 NFT = 1 libra).
- TomatoTrace → guarda la trazabilidad (strings fáciles de leer).
- TomatoCustody → custodia/listado/compra (venta simple con SCOL).

## Despliegue

### Despliega TomatoNFT.
- Despliega TomatoTrace pasando la dirección de TomatoNFT.
- Despliega TomatoCustody pasando la dirección de TomatoNFT.

**Acuñar**:
- En TomatoNFT.mintBatch(<tu_wallet_o_custodia>, cantidad).
- Si quieres que la Custodia reciba los NFTs de una: pasa to = TomatoCustody.

**Cargar trazabilidad**:
- En TomatoTrace.setLote(tokenId, Lote{...}), luego setProcesamiento(...), setDistribucion(...), setPuntoDeVenta(...), setVenta(...), setDocumentos(...).
- Puedes dar permisos a la planta/almacén con setOperator(addr,true).

**Listar y vender**
- Si los NFTs están en tu wallet: primero TomatoNFT.approve(TomatoCustody, tokenId) y luego TomatoCustody.deposit(tokenId).
- TomatoCustody.list(tokenId, priceWei).
- El comprador llama buy(tokenId) enviando msg.value = priceWei.
- La custodia transfiere el NFT al comprador y ETH al vendedor.

**Consulta**
- TomatoTrace.ver(tokenId) devuelve todos los structs con strings legibles.
