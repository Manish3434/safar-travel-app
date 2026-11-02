# AGENTS.md: Travel App (working name)

## What this project is
An India-wide travel app. A user searches any place (cities, villages, hidden forest spots) and sees
photos and details, distance from their live location, nearby stays, bus and transport timings,
weather, community posts, trip planning, safety tools, and an AI + voice assistant.

Full details live in @docs/PROJECT_BRIEF.md. Build in phases. Work on Phase 1 only unless told otherwise.

## Proposed stack (CONFIRM with the owner before Phase 1 starts)
- Mobile: Flutter (Dart). Android first, iOS second. Riverpod for state. Feature-based folders.
- Backend: NestJS (TypeScript) REST API, PostgreSQL + PostGIS, Redis cache, S3 for media.
- AI: Claude API, called ONLY from the backend, using tool-calling over our own endpoints.
- Infra: AWS (ap-south-1), Terraform, GitHub Actions CI.

## Working rules
1. Plan first. For any task that touches more than 3 files, write an implementation plan and wait for approval.
2. Never commit secrets. Keys live in environment variables or a secret manager. `.env` is git-ignored.
   Commit only `.env.example` with placeholder values.
3. Third-party API keys (Google, weather, hotels, AI) are used on the server only. The mobile app never holds them.
4. Every external data source sits behind an interface (PlacesProvider, RoutesProvider, WeatherProvider,
   StaysProvider, TransportProvider). Build a mock implementation first so work is not blocked on API approvals.
5. Respect provider terms. No scraping of Google, Yahoo, or Instagram. Use official APIs only.
6. Cache provider responses in Redis (short TTLs). Do not store provider data longer than its terms allow.
7. Never invent facts. If bus timings, prices, permit rules, or opening hours are missing, show
   "not available" with a last-updated time. The AI assistant must answer only from tool results.
8. Hidden and forest spots must always carry permit, safety, season, and network fields.
   Do not expose exact coordinates of spots flagged `sensitive`.
9. No hardcoded user-facing strings. Use localization from day one (English, Tamil, Hindi).
10. Privacy: ask for consent before location and microphone use. Do not store raw audio by default.
    Treat location data as personal data (India's DPDP Act).
11. Tests: add unit tests for services. Run lint and tests before saying a task is done.
12. Git: one feature per branch, small commits, clear messages. Never force-push. Never edit `.git/`.
13. Principal Engineer Quality Standard: Reject junior/fresher antipatterns. Always enforce Domain-Driven Clean Architecture (Presentation → Domain/UseCases → Data), typed `Result<T, AppFailure>` error handling, enterprise network resilience (exponential backoff retries, token interceptors), tactile haptic feedback, spring bounce physics (`BouncingScrollPhysics`), shimmer skeletons instead of spinners, and strict static analysis.

## Commands (fill in once the project is scaffolded)
- Backend: install, run, test, lint, migrate
- Mobile: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`
- Data Pipeline: `python data-pipeline/cli.py run --all`, `python data-pipeline/cli.py status`, `python data-pipeline/cli.py test-smoke`

## Do not
- Do not add features outside the current phase.
- Do not change the database schema without a migration file.
- Do not call paid APIs in tests. Use the mock providers.
- Do not run destructive commands (deleting folders, dropping tables) without asking.
