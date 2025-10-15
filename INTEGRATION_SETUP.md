# Frontend-Backend Integration Setup

## Project Structure
```
final-wishpers/
├── contracts/           # Smart contracts
├── server/              # Backend (NestJS + ElizaOS)
├── client/              # Frontend (React + Vite)
└── package.json         # Root workspace configuration
```

## Quick Start

1. **Install dependencies for all projects:**
   ```bash
   npm run install:all
   ```

2. **Start both frontend and backend in development mode:**
   ```bash
   npm run dev
   ```

3. **Or start them separately:**
   ```bash
   # Backend only (port 3001)
   npm run dev:be
   
   # Frontend only (port 3000)
   npm run dev:fe
   ```

## Port Configuration

- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:3001
- **API Proxy**: Frontend automatically proxies `/api/*` requests to backend

## Environment Variables

### Frontend (.env file in client/)
```bash
VITE_API_BASE_URL=http://localhost:3001
```

### Backend (.env file in server/)
```bash
PORT=3001
CORS_ORIGIN=http://localhost:3000
```

## Available Scripts

- `npm run dev` - Start both frontend and backend
- `npm run build` - Build both projects
- `npm run start:be` - Start backend in production mode
- `npm run start:fe` - Start frontend preview server

## API Integration

The frontend is configured to automatically proxy API calls to the backend:
- Frontend makes requests to `/api/*`
- Vite proxy forwards these to `http://localhost:3001/api/*`
- CORS is configured to allow frontend requests

## Development Workflow

1. Backend runs on port 3001 with hot reload
2. Frontend runs on port 3000 with hot reload
3. API calls are automatically proxied
4. Both projects can be developed simultaneously 