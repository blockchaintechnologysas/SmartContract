<!DOCTYPE html>
<html>
<head>
  <title>Strategic Governance</title>
  <script src="https://cdn.jsdelivr.net/npm/ethers@5.7.2/dist/ethers.min.js"></script>
</head>
<body>
  <h1>Governance dApp</h1>

  <button onclick="connectWallet()">🔌 Conectar Wallet</button>
  <p id="walletAddress">No conectado</p>

  <hr>

  <h2>Crear Propuesta</h2>
  <input type="text" id="proposalDesc" placeholder="Descripción de la propuesta">
  <button onclick="createProposal()">Crear</button>

  <hr>

  <h2>Propuestas Existentes</h2>
  <button onclick="loadProposals()">🔄 Cargar Propuestas</button>
  <div id="proposals"></div>

  <script>
    const contractAddress = "DIRECCION_DEL_CONTRATO";
    const abi = [ // ABI mínima
      "function createProposal(string memory description) public",
      "function proposalCount() view returns (uint256)",
      "function proposals(uint256) view returns (uint256 id, string memory description, uint256 endDate, uint256 yesVotes, uint256 noVotes, bool executed)",
      "function vote(uint256 proposalId, bool support) public",
      "function executeProposal(uint256 proposalId) public",
      "function hasVotingRight(address account) view returns (bool)"
    ];

    let provider, signer, contract;

    async function connectWallet() {
      if (!window.ethereum) return alert("Necesitas Metamask");
      await ethereum.request({ method: "eth_requestAccounts" });
      provider = new ethers.providers.Web3Provider(window.ethereum);
      signer = provider.getSigner();
      contract = new ethers.Contract(contractAddress, abi, signer);
      document.getElementById("walletAddress").innerText = await signer.getAddress();
    }

    async function createProposal() {
      const desc = document.getElementById("proposalDesc").value;
      try {
        const tx = await contract.createProposal(desc);
        await tx.wait();
        alert("Propuesta creada");
      } catch (err) {
        alert("Error: " + err.message);
      }
    }

    async function loadProposals() {
      const count = await contract.proposalCount();
      const container = document.getElementById("proposals");
      container.innerHTML = "";

      for (let i = 0; i < count; i++) {
        const p = await contract.proposals(i);
        container.innerHTML += `
          <div>
            <h3>#${p.id}: ${p.description}</h3>
            <p>Votos a favor: ${p.yesVotes}, en contra: ${p.noVotes}</p>
            <p>Finaliza: ${new Date(p.endDate * 1000).toLocaleString()}</p>
            <p>Ejecutada: ${p.executed}</p>
            <button onclick="vote(${p.id}, true)">👍 Sí</button>
            <button onclick="vote(${p.id}, false)">👎 No</button>
            <button onclick="execute(${p.id})">⚙️ Ejecutar</button>
          </div><hr>
        `;
      }
    }

    async function vote(id, support) {
      try {
        const tx = await contract.vote(id, support);
        await tx.wait();
        alert("Voto registrado");
      } catch (err) {
        alert("Error: " + err.message);
      }
    }

    async function execute(id) {
      try {
        const tx = await contract.executeProposal(id);
        await tx.wait();
        alert("Propuesta ejecutada");
      } catch (err) {
        alert("Error: " + err.message);
      }
    }
  </script>
</body>
</html>
