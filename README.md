# Safar 🗺️

> India's all-in-one travel companion — from "I want to go somewhere" to "I am there, safely."

**Status:** Phase 1 in development · Android-first · India only

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) · Riverpod · Go Router |
| Backend | NestJS (TypeScript) · REST API |
| Database | PostgreSQL 16 + PostGIS |
| Cache | Redis 7 |
| AI | Claude API (Phase 5) |
| Infra | AWS ap-south-1 · Docker for local dev |

---

## Project Structure

```
safar/
├── apps/
│   ├── backend/     ← NestJS API
│   └── mobile/      ← Flutter app
├── docs/
│   └── PROJECT_BRIEF.md
├── docker-compose.yml
├── .env.example
└── AGENTS.md
```

---

## Local Development Setup

### Prerequisites
- Node.js ≥ 20
- pnpm ≥ 9 (`npm install -g pnpm`)
- Docker Desktop
- Flutter ≥ 3.22 (for mobile)

### 1. Clone and install
```bash
git clone <repo-url> safar
cd safar
pnpm install
```

### 2. Environment variables
```bash
cp .env.example .env
# Edit .env — for local dev, the defaults work with Docker
```

### 3. Start infrastructure
```bash
docker compose up -d
# PostgreSQL on :5432, Redis on :6379
```

### 4. Run database migrations
```bash
pnpm backend:migrate
```

### 5. Start backend (with mock providers)
```bash
pnpm backend:dev
# API available at http://localhost:3000
# Health check: http://localhost:3000/health
```

### 6. Run Flutter app
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Environment Variables

Copy `.env.example` → `.env`. The defaults work for local dev with Docker.

Set `PROVIDER_MODE=mock` (default) to run without any third-party API keys.
Set `PROVIDER_MODE=real` and fill in API keys to use live providers.

---

## Running Tests

```bash
# Backend
pnpm backend:test       # unit tests (Jest)
pnpm backend:lint       # ESLint

# Mobile
cd apps/mobile
flutter analyze
flutter test
```

---

## Phase 1 Scope

Search, photos, distance, stays, bus timings (TN/KA/MH pilot), weather card, saved places, offline basics.

See [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md) for the full feature spec and [AGENTS.md](AGENTS.md) for working rules.

---

## Working Rules

See [AGENTS.md](AGENTS.md). Key points:
- Mock providers first — never blocked on API approvals
- No secrets in code — keys in `.env` only
- All user-facing strings are localized (en, ta, hi)
- Tests must pass before a task is marked done
