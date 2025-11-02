// Sync contract addresses from contracts/deployment.json into client/.env.local as VITE_ vars
// Usage: node scripts/sync-addresses.js
const fs = require('fs');
const path = require('path');

function main() {
  const deploymentPath = path.join(__dirname, '..', 'contracts', 'deployment.json');
  const clientEnvPath = path.join(__dirname, '..', 'client', '.env.local');

  if (!fs.existsSync(deploymentPath)) {
    console.error('Missing contracts/deployment.json. Deploy contracts first.');
    process.exit(1);
  }

  const raw = fs.readFileSync(deploymentPath, 'utf-8');
  let data;
  try {
    data = JSON.parse(raw);
  } catch (e) {
    console.error('Failed to parse deployment.json:', e.message);
    process.exit(1);
  }

  const agent = data.Agent || '';
  const vault = data.Vault || '';
  const base = data.WUSD || data.BaseToken || '';
  const pay = data.WPMT || data.PaymentToken || '';

  const lines = [
    `VITE_API_BASE_URL=${process.env.VITE_API_BASE_URL || 'http://localhost:3001'}`,
    `VITE_RPC_URL=${process.env.VITE_RPC_URL || 'http://127.0.0.1:8545/'}`,
    `VITE_AGENT_ADDRESS=${agent}`,
    `VITE_VAULT_ADDRESS=${vault}`,
    `VITE_BASE_TOKEN_ADDRESS=${base}`,
    `VITE_PAYMENT_TOKEN_ADDRESS=${pay}`,
    `APP_API_BASE_URL=${process.env.APP_API_BASE_URL || process.env.VITE_API_BASE_URL || 'http://localhost:3001'}`,
    `APP_RPC_URL=${process.env.APP_RPC_URL || process.env.VITE_RPC_URL || 'http://127.0.0.1:8545/'}`,
    `APP_AGENT_ADDRESS=${agent}`,
    `APP_VAULT_ADDRESS=${vault}`,
    `APP_BASE_TOKEN_ADDRESS=${base}`,
    `APP_PAYMENT_TOKEN_ADDRESS=${pay}`,
  ];

  fs.writeFileSync(clientEnvPath, lines.join('\n') + '\n', 'utf-8');
  console.log('Wrote client/.env.local with addresses:');
  console.log(lines.join('\n'));
}

main();