// Lightweight RPC check using native fetch; avoids requiring ethers

async function main() {
  const netName = (process.env.HARDHAT_NETWORK || "somniaTestnet");
  const url = process.env.CHAIN_RPC_URL || process.env.SOMNIA_TESTNET_RPC_URL || process.env.SOMNIA_RPC_URL || "https://dream-rpc.somnia.network";
  const chainIdEnv = process.env.CHAIN_ID ? Number(process.env.CHAIN_ID) : undefined;
  if (!url) {
    console.error("Missing RPC URL. Set CHAIN_RPC_URL or SOMNIA_TESTNET_RPC_URL.");
    process.exit(1);
  }
  // Query eth_chainId
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "eth_chainId", params: [] })
  });
  if (!res.ok) {
    console.error(`RPC request failed: HTTP ${res.status}`);
    process.exit(1);
  }
  const json = await res.json();
  const hexId = json && json.result;
  if (!hexId) {
    console.error("RPC didn't return chainId. Response:", json);
    process.exit(1);
  }
  const chainId = Number(hexId);
  console.log(`RPC network OK: url=${url}`);
  console.log(`RPC chainId=${chainId}`);
  if (chainIdEnv !== undefined) {
    console.log(`Env chainId=${chainIdEnv}`);
    if (chainIdEnv !== chainId) {
      console.error("Mismatch: set CHAIN_ID to the RPC's chainId above.");
      process.exit(2);
    }
  }
  const pk = process.env.PRIVATE_KEY;
  if (!pk) {
    console.warn("PRIVATE_KEY not set. Set it in contracts/.env to deploy.");
  } else {
    if (!(pk.startsWith("0x") && pk.length === 66)) {
      console.warn("PRIVATE_KEY format looks unusual; expected 0x-prefixed 32-byte hex.");
    }
  }
  console.log(`Signer env present for ${netName}.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
require("dotenv").config();