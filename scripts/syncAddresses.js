const fs = require("fs");
const path = require("path");

function main() {
  const deploymentPath = path.join(__dirname, "../contracts/deployment.json");
  const mdPath = path.join(__dirname, "../DEPLOYED_ADDRESSES.md");
  if (!fs.existsSync(deploymentPath)) {
    console.error("contracts/deployment.json not found. Run your deploy first.");
    process.exit(1);
  }
  const d = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
  const lines = [];
  lines.push("# Deployed Addresses (Wishpers)");
  lines.push("");
  lines.push(`- Network: ${d.network || "unknown"}`);
  lines.push(`- Timestamp: ${d.timestamp || new Date().toISOString()}`);
  if (d.deployer) lines.push(`- Deployer: \`${d.deployer}\``);
  if (d.treasury) lines.push(`- Treasury: \`${d.treasury}\``);
  lines.push("");
  lines.push("## Core Contracts");
  const c = d.contracts || {};
  Object.entries(c).forEach(([k,v]) => {
    lines.push(`- ${k}: \`${v}\``);
  });
  lines.push("");
  lines.push("## Tokens (Faucet)");
  const t = d.tokens || {};
  if (t.base) lines.push(`- Mock USDC (FaucetToken): \`${t.base}\``);
  const e = (t.extra || {});
  Object.entries(e).forEach(([k,v]) => lines.push(`- ${k} (FaucetToken): \`${v}\``));
  lines.push("");
  lines.push("## Adapters");
  const a = d.adapters || {};
  Object.entries(a).forEach(([k,v]) => {
    lines.push(`- ${k}: \`${v}\``);
  });
  const m = d.mocks || {};
  if (Object.keys(m).length) {
    lines.push("  - Mocks:");
    Object.entries(m).forEach(([k,v]) => {
      if (typeof v === "object") {
        lines.push(`    - ${k}: ${JSON.stringify(v)}`);
      } else {
        lines.push(`    - ${k}: \`${v}\``);
      }
    });
  }
  lines.push("");
  lines.push("## Notes");
  lines.push("- These addresses are sourced from `contracts/deployment.json`.\n");
  fs.writeFileSync(mdPath, lines.join("\n"));
  console.log("DEPLOYED_ADDRESSES.md updated from deployment.json");
}

main();