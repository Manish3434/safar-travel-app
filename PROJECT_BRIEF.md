# Travel App: Project Brief

Working name: TBD | Version 0.1 | Date: 29 Oct 2026 | Status: draft for build planning

Tags used below: [P1] to [P5] mean the phase a feature belongs to. Build Phase 1 first.

---

## 1. Vision

One app that takes a traveller from "I want to go somewhere" to "I am there, safely".
The user searches any place in India, from a big city to a remote village or a hidden forest spot.
The app locates it exactly, shows photos and details, calculates distance from the user's live location,
suggests stays and bus timings, shows weather, and lets travellers share what they saw.
A voice-enabled AI assistant helps plan trips.

### Goals
- Exact place search with photos and details for all of India.
- Real distance and travel time from the user's location.
- Stays and transport suggestions near the place.
- Hidden-spot discovery with safety and permit information.
- Community content owned by us (posts, hashtags, reviews), not scraped.
- Works in weak-network areas (offline maps and saved places).
- Tamil, Hindi, and English from the start.

### Non-goals (for now)
- Flight and train ticket booking.
- Scraping Google, Yahoo, or Instagram.
- Worldwide coverage (India only at first).

---

## 2. Users and scenarios

| User | Example scenario |
|---|---|
| Family or weekend traveller | "Quiet waterfall within 3 hours, good road, under Rs 4,000." |
| Solo or women traveller | Wants verified safe stays and to share live location with family. |
| Trekker or nature lover | Wants hidden forest spots, season info, permit and guide details. |
| Local homestay owner or guide | Lists rooms and services, receives bookings. |
| Tourism department (later) | Sees anonymous, aggregated visitor trends. |

---

## 3. Phases at a glance

| Phase | Theme | Main outcome |
|---|---|---|
| P1 | Core app | Search, photos, distance, stays, bus timings (pilot states), weather card, saved places, offline basics |
| P2 | Community and planning | Posts, hashtags, reviews, Q&A, hidden spots, trip planner, best time to visit |
| P3 | Transport and safety | Last-bus alerts, last-mile transport, SOS, check-in timer, weather alerts |
| P4 | Marketplace and booking | Owner dashboard, guides, permit and guide booking, visitor slots, offline state packs |
| P5 | AI, voice, engagement | AI assistant, voice, photo recognition, journal, rewards, tourism dashboard |

---

## 4. Feature specification

### A. Search and places [P1]
- Search box with autocomplete. Search by name, category, or "near <place>".
- Result card: name, category, main photo, distance, rating, one-line description.
- Place page: photo gallery, description, map pin, opening hours, how to reach, nearby places,
  weather card, nearby stays, transport section, Save button.
- Exact location: coordinates and map pin. Button to open turn-by-turn navigation in the phone's map app.
- Data is merged from several providers plus our own database. Each field stores its source and fetched_at.
- Remote villages: if the main provider has no data, fall back to OpenStreetMap and community data.
  Provide a "Suggest a place" form.

### B. Location and distance [P1]
- Explain why location is needed, then request permission. The app still works without it (user picks a "from" city).
- Road distance and travel time from a routes provider. Fallback: straight-line distance, labelled "approx".
- "Near me" sorting and filters (category, radius).

### C. Stays [P1 basic, P4 owner dashboard]
- Hotels, lodges, homestays near a place from partner APIs. Filters: price, rating, distance, type.
- Map view of stays around the attraction.
- P4: owners sign up, verify, add rooms, photos, prices, and availability.

### D. Transport [P1 pilot states, P3 full]
- P1: bus timings for 2 to 3 pilot states, from official or partner data (or manually curated at first).
- Show "last updated" and source. Never guess a timing.
- P3: last-bus alert and reminder, last-mile options (shared auto, jeep, ferry) with typical fares,
  bus/train/cab side by side, live tracking only where an agency provides it,
  parking, fuel, EV charging, road suitability (car, bike only, 4x4 in monsoon), fair price guide.

### E. Community [P2]
- Photo and video posts tagged to a place, with hashtags (stored in our own database).
- Ratings and reviews, questions and answers, live updates (crowd, road condition, closure).
- Contributor badges. Report button on every post. Moderation queue.
- "Share to Instagram" with a pre-filled app hashtag and place hashtag.
- Optional later: Instagram hashtag lookup for a few popular places (limited by Meta's API rules).

### F. Hidden and forest spots [P2]
- Spot submission with photos, GPS, difficulty, best season, permit needed, guide needed, network availability,
  nearest road and hospital, wildlife or weather warnings.
- Human review before a spot goes public.
- Sensitive spots show only an approximate area. Exact route is given after a permit or guide booking (P4).
- Never encourage entry into restricted or protected areas. Show permit rules clearly.

### G. Trip planning [P2]
- Save places, build a multi-day itinerary, reorder stops by route.
- Shareable itinerary link or PDF (opens without installing the app).
- Budget tracker and expense splitting with friends.
- Best time to visit (monthly climate), seasonal highlights calendar, packing checklist.
- Local rules and etiquette, local food and festivals, phone signal (Jio, Airtel, Vi), UPI and ATM availability.

### H. Safety [P3]
- SOS button and live location sharing with chosen contacts.
- Check-in timer: user sets a return time; if no check-in, contacts are alerted (server-side, works without phone signal).
- Nearby hospitals, police, ATMs, toilets. Regional emergency numbers available offline.
- Weather safety alerts (Google weather plus IMD warnings). Offline first-aid guide reviewed by a medical professional.
- Scam and overcharge reports. Solo and women travellers mode. Accessibility filters. Group trips.

### I. Weather and climate [P1 card, P2 climate, P3 alerts]
- Current conditions, hourly and 10-day forecast for the exact place.
- Monthly climate averages from a historical source, stored once per place.
- Cache current conditions about 10 to 15 minutes and forecasts about 1 hour. Share results between nearby users.
- Label remote-spot forecasts "forecast for the nearby area".

### J. AI assistant [P5]
- Trip planning by chat ("2 days, family, under Rs 5,000").
- Natural-language search ("quiet waterfall within 3 hours with a good road").
- Questions about a place, review and post summaries, replanning when weather or closures change.
- Uses tools that call our own endpoints (places, distance, stays, transport, weather, permits).
- Must answer only from tool results. If data is missing, say so.

### K. Voice [P5]
- Pipeline: mic, streaming speech-to-text, backend, Claude with tools, short answer, text-to-speech.
- Languages: English, Tamil, Hindi, and mixed speech. Feed place names as hints to the speech service.
- Keep spoken answers to 1 to 3 sentences. Show details on screen.
- Tap-to-talk first. Voice SOS needs a confirmation countdown. A few offline commands on the device.

### L. Marketplace and booking [P4]
- Verified guides and drivers, forest permit and guide booking, visitor time slots for fragile spots.
- Stay check-in by QR code (also confirms real visits for reviews).
- Revenue: commissions, clearly marked sponsored listings, paid tier.

### M. Engagement and extras [P5]
- Travel journal and India map that fills as states are visited, contributor rewards.
- Audio guide at places, photo recognition, camera translation, phrasebook with audio.
- Opt-in nearby alerts. "Surprise me" trips. Crowd meter.
- Anonymous tourism board dashboard (no individual user data).

---

## 5. Data sources and rules

| Need | Candidate source | Rules and cautions |
|---|---|---|
| Places, photos, ratings | Google Places API | Server-side only. Check current terms for what may be cached or stored; normally only place IDs are stored long term. Show required attributions. |
| Open place data (waterfalls, viewpoints, trails) | OpenStreetMap | Free, good for remote spots. Quality varies. Respect its licence and attribution. |
| Distance and travel time | Google Routes API (or an alternative) | Cache by origin and destination area. Fallback to straight-line distance. |
| Weather | Google Weather API | Check current pricing and India coverage before relying on alerts. |
| Official warnings | IMD (India Meteorological Department) | Use for cyclone, flood, heavy rain warnings. |
| Monthly climate | A historical weather source (for example Open-Meteo or NASA POWER) | One-time import per place. Check licence for commercial use. |
| Hotels | Partner or affiliate APIs (Booking.com, Expedia, Agoda, Amadeus) | Needs approval. Build with a mock provider first. |
| Bus timings | State transport data, GTFS feeds where available, intercity booking partners | No single national source. Roll out state by state. Show source and last-updated. |
| Instagram hashtags | Meta Instagram hashtag search | Needs a Business or Creator account and Meta app review. Limited to 30 unique hashtags per 7 days, recent posts only, no identifying details. Optional extra only. |
| AI | Claude API | Backend only. Cache, rate limit per user, cap answer length. |
| Speech | Google Speech services, Bhashini, or an Indian-language provider | Test with real Tamil, Hindi, English audio before choosing. |

Hard rule: no scraping of Google, Yahoo, or Instagram.

---

## 6. Architecture

```
Mobile app (Flutter)
   |  HTTPS (JWT auth)
NestJS API  ---- Redis (cache, rate limits)
   |   \
   |    +-- Provider layer (interfaces + real + mock implementations)
   |           PlacesProvider, RoutesProvider, WeatherProvider,
   |           StaysProvider, TransportProvider, SpeechProvider
   |
PostgreSQL + PostGIS (our data)      S3 + CDN (photos, videos)
   |
Background jobs (queues): ingest, moderation, notifications, check-in timers
   |
AI service module (Claude API + tool endpoints)
```

Key decisions:
- Provider abstraction everywhere, so mock data lets the team build before approvals arrive.
- Geo queries ("near me") use PostGIS.
- Media uploads go straight to object storage using signed URLs. Create thumbnails in a background job.
- Offline: the app caches saved places, last forecast, and map tiles for chosen regions.
- Notifications: push for check-in reminders, last-bus alerts, and safety warnings.
- Localization: all strings in resource files (en, ta, hi). Place names stored in multiple languages where available.

---

## 7. Core data model (starting point)

- users, devices, consents
- places (id, name, name_i18n, category, location geography, source_ids, sensitive, created_at)
- place_media, place_sources (source, external_id, fetched_at)
- place_safety (permit_required, guide_required, difficulty, best_season, network_info, warnings)
- stays, stay_rooms, stay_owners (P4)
- transport_stops, transport_routes, transport_trips (stop_times), data_sources
- saved_places, trips, itinerary_items, expenses
- posts, post_media, hashtags, post_hashtags, reviews, questions, answers, live_updates, reports
- safety_contacts, checkins, sos_events
- climate_monthly (place_id, month, avg_temp, rainfall)
- guides, bookings, permits (P4)
- ai_conversations, ai_tool_calls (store minimal text, no raw audio)

---

## 8. Phase 1 API (first draft)

- POST /auth/login, POST /auth/refresh
- GET /places/search?q=&lat=&lng=
- GET /places/:id
- GET /places/nearby?lat=&lng=&radius=&category=
- GET /places/:id/distance?lat=&lng=
- GET /places/:id/weather
- GET /places/:id/stays
- GET /transport/routes?from=&to=&date=
- GET/POST/DELETE /saved-places
- GET /health

Every response that comes from a third party includes `source` and `fetched_at`.

---

## 9. Safety, legal, and privacy requirements

- Location and microphone: explicit consent, clear purpose text, easy to revoke.
- Data protection: treat location and posts as personal data under India's DPDP Act. Get legal review before launch.
- User content: moderation queue, report button, takedown process, terms of use.
- Safety information (first aid, weather, trail difficulty) is guidance, not professional advice. Show disclaimers. Medical content must be reviewed by a qualified professional.
- Protected areas: always show permit rules. Do not promote entry into restricted areas.
- Sensitive spots: approximate location only until a permit or guide booking exists.
- AI: no invented facts, no advice that encourages unsafe actions, clear "may be wrong" notice for photo recognition.
- Security: server-side API keys, rate limiting, input validation, signed upload URLs, dependency scanning in CI.

---

## 10. Non-functional requirements

- Search results in under 2 seconds on a normal mobile connection (cached results faster).
- Works with weak signal: saved places, last forecast, and downloaded map regions available offline.
- Voice replies start within about 2 seconds (streaming).
- Accessible: screen reader labels, scalable text, good contrast.
- Cost control: caching, per-user daily limits for AI and speech, monitoring of third-party API spend.
- Observability: structured logs, error tracking, dashboards for API latency and provider errors.

---

## 11. Risks and open decisions

| Item | Note |
|---|---|
| Mobile framework | Flutter proposed. Confirm before starting. |
| Bus data | Hardest part. Pick 2 to 3 pilot states and confirm sources early. |
| Hotel API approval | Can take weeks. Start now. |
| Google API cost at scale | Cache heavily. Consider an OpenStreetMap-based map later. |
| Moderation workload | Needs staff or trusted reviewers for hidden spots and posts. |
| Liability for safety content | Legal review needed. |
| Permits and forest departments | Partnerships needed for P4. |
| App name, branding | Not decided. |

---

## 12. Phase 1 work breakdown (can run in parallel)

1. Repo setup: monorepo or two repos, CI (lint, test, build), `.env.example`, README.
2. Backend skeleton: NestJS, config, auth, health, database and migrations, Redis.
3. Provider interfaces and mock implementations for places, routes, weather, stays, transport.
4. Places search and place details endpoints (mock first, then real provider).
5. Nearby and distance endpoints, with straight-line fallback.
6. Weather endpoint with caching.
7. Stays endpoint (mock first).
8. Transport pilot: import data for 2 to 3 states, routes endpoint, "last updated" display.
9. Mobile shell: navigation, theming, localization (en, ta, hi), login.
10. Mobile search and place page UI.
11. Location permission flow and distance display.
12. Saved places with offline cache.
13. Basic offline map region download.
14. Tests, accessibility pass, performance check, release build.

Definition of done for each task: code merged to a feature branch, lint and tests pass, mock and real
providers both work behind the interface, no secrets in the repo, and a short note on how to verify it.

---

## 13. How to use this brief with Antigravity

- Keep `AGENTS.md` short (rules only). Keep this brief in `docs/` and mention it with `@docs/PROJECT_BRIEF.md`.
- Start with `/grill-me` so the agent asks about anything unclear, then use `/plan` for Phase 1.
- Give each parallel task its own conversation or worktree and review the implementation plan before approving.
