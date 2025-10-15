# ElizaOS AI Agent Creation Guide

## 🎯 **What is ElizaOS?**

ElizaOS is an agentic operating system for building AI agents that can:
- **Execute real operations** (not just chat replies)
- **Chain actions together** with LLM-driven decision making
- **Collaborate with other agents** in swarms
- **Interface with multiple platforms** (Discord, Telegram, HTTP, blockchain)

## 🚀 **Quick Start: Creating Your First AI Agent**

### **1. Basic Agent Setup**

```typescript
import { ElizaOS } from '@elizaos/core';
import { ElizaServer } from '@elizaos/server';

// Create an ElizaOS instance
const eliza = new ElizaOS({
  name: 'Trading Agent Alpha',
  description: 'An autonomous trading agent for SEI blockchain',
  capabilities: ['trading', 'analysis', 'risk-management']
});

// Start the ElizaOS server
const server = new ElizaServer({
  port: 3001,
  agents: [eliza]
});

server.start();
```

### **2. Agent Capabilities & Plugins**

```typescript
// Import ElizaOS plugins
import { SeiPlugin } from '@elizaos/plugin-sei';
import { SqlPlugin } from '@elizaos/plugin-sql';
import { OllamaPlugin } from '@elizaos/plugin-ollama';

// Configure plugins
eliza.use(new SeiPlugin({
  network: 'testnet',
  rpcUrl: 'https://sei-testnet-rpc.com'
}));

eliza.use(new SqlPlugin({
  connectionString: 'postgresql://localhost/elizaos'
}));

eliza.use(new OllamaPlugin({
  model: 'llama3.2',
  baseUrl: 'http://localhost:11434'
}));
```

### **3. Defining Agent Actions**

```typescript
// Define what your agent can do
eliza.defineAction('analyze_market', {
  description: 'Analyze current market conditions',
  parameters: {
    tokens: { type: 'array', items: { type: 'string' } },
    timeframe: { type: 'string', enum: ['1h', '4h', '1d'] }
  },
  handler: async (params) => {
    // Your market analysis logic here
    const analysis = await performMarketAnalysis(params.tokens, params.timeframe);
    return {
      sentiment: analysis.sentiment,
      confidence: analysis.confidence,
      recommendations: analysis.recommendations
    };
  }
});

eliza.defineAction('execute_trade', {
  description: 'Execute a trade on SEI blockchain',
  parameters: {
    token: { type: 'string' },
    action: { type: 'string', enum: ['buy', 'sell'] },
    amount: { type: 'number' },
    maxSlippage: { type: 'number' }
  },
  handler: async (params) => {
    // Execute trade logic
    const result = await executeTrade(params);
    return {
      txHash: result.txHash,
      status: result.status,
      executedPrice: result.price
    };
  }
});
```

### **4. Agent Decision Making**

```typescript
// Define agent's decision-making process
eliza.defineWorkflow('trading_cycle', {
  description: 'Complete trading cycle with analysis and execution',
  steps: [
    {
      name: 'market_analysis',
      action: 'analyze_market',
      parameters: { tokens: ['SEI', 'USDC'], timeframe: '1h' }
    },
    {
      name: 'decision',
      type: 'llm_decision',
      prompt: `
        Based on the market analysis, decide whether to:
        1. Buy SEI (if bullish)
        2. Sell SEI (if bearish)
        3. Hold (if neutral)
        
        Market Analysis: {{market_analysis}}
        Current Portfolio: {{portfolio}}
        
        Provide your decision with confidence level (0-100).
      `
    },
    {
      name: 'execute_if_confident',
      type: 'conditional',
      condition: '{{decision.confidence > 70}}',
      action: 'execute_trade',
      parameters: {
        token: 'SEI',
        action: '{{decision.action}}',
        amount: '{{calculate_position_size()}}',
        maxSlippage: 0.02
      }
    }
  ]
});
```

### **5. Agent Memory & Learning**

```typescript
// Configure agent memory
eliza.configureMemory({
  type: 'ipfs',
  retention: '30d',
  learning: {
    enabled: true,
    feedbackLoop: true,
    adaptationRate: 0.1
  }
});

// Agent learns from outcomes
eliza.on('action_completed', async (event) => {
  if (event.action === 'execute_trade') {
    // Learn from trade outcome
    const outcome = await analyzeTradeOutcome(event.result);
    eliza.learn('trading_patterns', {
      market_conditions: event.context.market_analysis,
      decision: event.context.decision,
      outcome: outcome,
      timestamp: new Date()
    });
  }
});
```

### **6. Agent Communication**

```typescript
// Agent can communicate with users
eliza.defineInterface('discord', {
  type: 'discord',
  token: process.env.DISCORD_TOKEN,
  channels: ['#trading-signals', '#portfolio-updates']
});

// Agent can send notifications
eliza.defineAction('send_alert', {
  description: 'Send trading alert to Discord',
  parameters: {
    message: { type: 'string' },
    urgency: { type: 'string', enum: ['low', 'medium', 'high'] }
  },
  handler: async (params) => {
    await eliza.interfaces.discord.send(params.message, {
      urgency: params.urgency,
      channel: '#trading-signals'
    });
  }
});
```

### **7. Running Your Agent**

```typescript
// Start the agent
await eliza.start();

// Trigger trading cycle
await eliza.executeWorkflow('trading_cycle', {
  context: {
    portfolio: await getCurrentPortfolio(),
    market_conditions: 'volatile'
  }
});

// Agent runs autonomously
eliza.setAutonomy({
  enabled: true,
  schedule: '*/15 * * * *', // Every 15 minutes
  workflows: ['trading_cycle']
});
```

## 🔧 **Integration with Your Backend**

### **Agent Service Integration**

```typescript
// In your agent.service.ts
import { ElizaOS } from '@elizaos/core';

export class AgentService {
  private agents = new Map<string, ElizaOS>();

  async createAgent(soulId: string, config: any): Promise<AgentDocument> {
    // Create ElizaOS agent
    const elizaAgent = new ElizaOS({
      name: `Soul Agent ${soulId}`,
      description: `AI agent for soul ${soulId}`,
      capabilities: config.capabilities || ['general']
    });

    // Configure plugins based on soul traits
    if (config.capabilities.includes('trading')) {
      elizaAgent.use(new SeiPlugin({
        network: 'testnet',
        rpcUrl: process.env.SEI_RPC_URL
      }));
    }

    // Store agent reference
    this.agents.set(soulId, elizaAgent);

    // Start the agent
    await elizaAgent.start();

    return this.agentModel.create({
      soulId,
      agentId: soulId,
      config,
      status: 'active'
    });
  }
}
```

## 📊 **Example: Trading Agent**

Here's a complete example of a trading agent:

```typescript
// trading-agent.ts
import { ElizaOS } from '@elizaos/core';
import { SeiPlugin } from '@elizaos/plugin-sei';

class TradingAgent {
  private eliza: ElizaOS;

  constructor() {
    this.eliza = new ElizaOS({
      name: 'SEI Trading Agent',
      description: 'Autonomous trading agent for SEI blockchain'
    });

    this.setupCapabilities();
    this.setupWorkflows();
  }

  private setupCapabilities() {
    // Market analysis
    this.eliza.defineAction('analyze_sei_market', {
      description: 'Analyze SEI market conditions',
      handler: async () => {
        const marketData = await this.fetchMarketData();
        return this.analyzeMarketConditions(marketData);
      }
    });

    // Portfolio management
    this.eliza.defineAction('rebalance_portfolio', {
      description: 'Rebalance portfolio based on strategy',
      handler: async (params) => {
        return await this.executeRebalancing(params);
      }
    });
  }

  private setupWorkflows() {
    this.eliza.defineWorkflow('daily_trading', {
      steps: [
        { name: 'market_analysis', action: 'analyze_sei_market' },
        { name: 'portfolio_check', action: 'check_portfolio_health' },
        { name: 'rebalance', action: 'rebalance_portfolio' }
      ]
    });
  }

  async start() {
    await this.eliza.start();
    
    // Schedule daily trading
    this.eliza.setAutonomy({
      enabled: true,
      schedule: '0 9 * * *', // 9 AM daily
      workflows: ['daily_trading']
    });
  }
}
```

## 🎯 **Next Steps**

1. **Start the backend** to test ElizaOS integration
2. **Create your first agent** using the examples above
3. **Configure plugins** for your specific use case
4. **Deploy agents** to production

Your ElizaOS integration is ready! The agents will be able to:
- Analyze markets autonomously
- Execute trades on SEI blockchain
- Learn from outcomes
- Communicate with users
- Collaborate with other agents

Would you like me to start the backend to test this integration, or would you prefer to see more specific examples?

## 🔧 **Environment Variables Setup**

### **Backend Environment (.env in server/)**

```bash
# Server Configuration
PORT=3001
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000

# Database (MongoDB)
MONGODB_URI=mongodb://localhost:27017/immortal-souls

# JWT Authentication
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d

# IPFS Configuration
IPFS_PROVIDER=pinata
IPFS_PINATA_API_KEY=your-pinata-api-key
IPFS_PINATA_SECRET_KEY=your-pinata-secret-key
IPFS_GATEWAY_URL=https://gateway.pinata.cloud/ipfs/

# SEI Blockchain
SEI_RPC_URL=https://sei-testnet-rpc.com
SEI_CHAIN_ID=sei-testnet
SEI_PRIVATE_KEY=your-wallet-private-key

# ElizaOS Configuration
ELIZAOS_MODEL_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2
```

### **Frontend Environment (.env in client/)**

```bash
VITE_API_BASE_URL=http://localhost:3001
```

### **Where to Get Services:**

- **IPFS**: [pinata.cloud](https://pinata.cloud) (free tier available)
- **SEI Testnet**: Use public RPC or run your own node
- **AI Models**: [ollama.ai](https://ollama.ai) for local models 