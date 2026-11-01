# Biljakt

**Biljakt** (formerly Galen): a kid-friendly Swedish iOS app (SwiftUI, iOS 17) where you spot cars by Swedish license plate and hunt colors, kinds and brands with friends, plus an ASP.NET Core 8 API that stores your finds. There is no driver rating any more (removed 2026-11-01). Everything is named Biljakt: Xcode project `Biljakt.xcodeproj`, target/scheme/module `Biljakt`, folder `Biljakt/`, theme enum `AppStyle`. The API project is `BiljaktAPI/` and the database tables are `Biljakt*`. Still named PlateRater (can't change from code): the GitHub repo name, the iOS bundle ID `com.ibrahimaweidah.PlateRater` (tied to the Google OAuth client) and the database name `db_a30625_platerater`. The app is a product of **Ibrax AB** (shown on splash, sign-in, profile menu, and as the copyright in Info.plist).

## Layout

- `Biljakt/` – the iOS app (target and scheme `Biljakt`, entry point `BiljaktApp.swift` with a splash screen). Open `Biljakt.xcodeproj` in Xcode to build and run.
  - `Assets.xcassets` – `AppIcon` and `BiljaktLogo` (same 1024px image), pink `AccentColor`.
  - `AuthManager.swift` – Google sign-in (GoogleSignIn-iOS 8.x via Swift Package Manager).
  - `APIClient.swift` – calls the API with the Google ID token as a bearer token.
  - `RatingStore.swift`, `PlateDetailView.swift`, `ContentView.swift` (tabs: Spana, Mina bilar, Jakt, Tävla), `MyRatingsView.swift`, `ColorHuntView.swift` (Jakt: colors, car kinds and brands), `FriendsView.swift` (friends and leaderboard), `SignInView.swift` – UI and state.
  - `PlateScanner.swift` – reads the plate from a photo on the device (Apple Vision text recognition, no server, free). Used by "Fota skylten" on the Spana tab; the photo is then attached to the rating.
  - `CarGuesser.swift` – guesses color (car cut out with Vision foreground mask, pixels vote for a `CarColor`), brand (text on the car via Vision OCR) and kind (Vision image classifier) from the rating photo, on the device. Fills empty fields and warns when the photo doesn't match what the user picked.
  - `Theme.swift` – colors and fonts (`AppStyle`), `CarColor`, `CarKind` and `CarBrand` (keys must match `CarColors`, `CarKinds` and `CarBrands` in the API), `HuntScore`, `SpotterRank`.
  - UI text is Swedish. Bundle ID stays `com.ibrahimaweidah.PlateRater` (Google OAuth client is tied to it); display name is Biljakt.
  - `Config.xcconfig` – `GOOGLE_CLIENT_ID`, `GOOGLE_REVERSED_CLIENT_ID`, `API_BASE_URL`, fed into `Info.plist`. In xcconfig `//` starts a comment, so URLs are written `https:/$()/host/`.
- `BiljaktAPI/` – ASP.NET Core 8 minimal API (`Program.cs`, `AppDb.cs`, builds `BiljaktAPI.dll`), EF Core with SQL Server.
  - `schema.sql` – the whole schema (`BiljaktUsers`, `BiljaktRatings`, `BiljaktPhotos`, `BiljaktFriendships`) for a fresh database.
  - `migrate-to-biljakt.sql` – one-time migration of the production database from the old `PlateRater*` tables: renames tables and constraints, makes `Score` nullable, adds `PlateRater*` synonyms so an older API keeps working.
  - `appsettings.json` – connection string `Biljakt` with a `YOUR-DB-PASSWORD` placeholder. Never commit the real password. The server's own appsettings.json still names the connection string `PlateRater`; Program.cs reads `Biljakt` and falls back to `PlateRater`.
- `SETUP.md` – step-by-step setup guide.

## How it fits together

- The app signs in with Google and sends the ID token on every request. The API validates it against Google's keys (JwtBearer, authority `https://accounts.google.com`, audience = the iOS client ID in `Google:ClientIds`).
- Endpoints: `GET /api/plates/{plate}`, `PUT /api/plates/{plate}/rating` (`{comment, color, kind, brand}`; `score` optional and unused by the app), `DELETE /api/plates/{plate}/rating`, `PUT|GET|DELETE /api/plates/{plate}/rating/photo` (raw JPEG/PNG body, max 3 MB), `GET /api/me/ratings`, `GET|POST /api/friends` (`{email}`), `POST /api/friends/{id}/accept`, `DELETE /api/friends/{id}`. One rating per Google account per plate. Ratings are private: every endpoint returns only the signed-in user's own ratings, comments and photos, never anyone else's (decided 2026-11-01 after a legal review, to keep personal data about car owners from being shown to others). Friends, added by Google e-mail and accepted by the other side, see only each other's first name and which colors, kinds and brands of car they found.

## Where things run

- API: SmarterASP.NET site at https://ibrahimawe-001-site5.ftempurl.com/ (temporary SmarterASP address; https works). Deployed with the GitHub Actions workflow `.github/workflows/deploy-api.yml` (runs on every push that changes BiljaktAPI/ on main or the Biljakt branch, or Actions > Deploy API to SmarterASP > Run workflow; builds, uploads over FTPS with app_offline.htm, never touches the server's appsettings.json; needs secrets FTP_HOST, FTP_USER, FTP_PASSWORD, FTP_DIR). Manual fallback: upload the output of `dotnet publish -c Release` via FTP. SmarterASP is shared IIS hosting, no containers. The deployed copy with the real password lives in the git-ignored `publish/` folder of the old `PlateRaterAPI/` on the Mac.
- Database: SmarterASP MSSQL `db_a30625_platerater` on `sql6032.site4now.net`, a database of its own (seen 2026-11-01; earlier the tables lived in `DB_A30625_ibrahimawe` on `sql6018`, shared with Ibrax_1). The API's connection string on the server must point here.
- Google Cloud project "Ibrax": iOS OAuth client `619027614244-cnrk7d54uq6ah0i55kbooandipf6dl49.apps.googleusercontent.com`, bundle ID `com.ibrahimaweidah.PlateRater`. Consent screen is in Testing; only listed test users can sign in.

## Status

- The original API is deployed and the first Xcode build succeeded.
- schema-2 and schema-3 are run; the Biljakt API was deployed 2026-11-01 13:42 UTC by the GitHub Actions workflow (check passed: /api/friends → 401). `migrate-to-biljakt.sql` must be run before `AppDb.cs` switches to the `Biljakt*` table names (user was asked 2026-11-01). The Swift code after the rename has not been compiled yet.
- No free API gives Swedish vehicle data (make/model/color) by plate; Transportstyrelsen and the commercial options (biluppgifter.se, car.info, tic.io, minbilkoll.se) need an agreement or a paid plan.

## Branches

- `main` – the original app (then called PlateRater) with the backend.
- `claude/project-thread-m1xtn2` (PR #1) – Galen rebrand: colors, photos, Mina betyg, color hunt, plate OCR, icon and splash.
- `claude/project-thread-y1essk` (PR #2) – built on PR #1: Biljakt rename, no driver rating, private ratings, car-kind and brand hunt, photo guessing, friends and leaderboard. Merge PR #1 first.

## Legal review (2026-11-01)

A Swedish-law review (not by a lawyer) is at https://claude.ai/artifact/SpgPu9NR3xbetS37BPqkhL. Main points and what is still open before App Store launch:

- Done: ratings, comments and photos are private (only the author sees them), because public ratings of a plate are personal data about the car owner and free text can be defamation.
- Keep it that way: never show one user's plates, ratings, comments or photos to another user, friends included.
- Still to do: privacy policy and terms (link in the app), in-app account deletion, Sign in with Apple, 13-year age limit, "never use while driving" warning, data retention, SmarterASP data processing agreement and data location, own DB user separate from Ibrax_1, a real domain with its own certificate. A lawyer should review before launch.

## Recent changes (newest first)

Keep this list up to date: add a line here whenever you change the app, the API or the database, so the next session (on any device) knows the current state.

- 2026-11-01 – Renamed the rest to Biljakt: `PlateRaterAPI/` → `BiljaktAPI/` (BiljaktAPI.dll, namespace BiljaktAPI), Info.plist key `BiljaktAPIBaseURL`, connection string `Biljakt` (falls back to `PlateRater`), new `schema.sql` with `Biljakt*` tables and `migrate-to-biljakt.sql`; old schema-2/3/4 scripts removed (schema-4 would have failed: a CHECK constraint blocks ALTER COLUMN).
- 2026-11-01 – First automatic deploy via GitHub Actions succeeded (FTP secrets set; deploys on push to PlateRaterAPI/ on main or the Biljakt branch).
- 2026-11-01 – Full rename Galen → Biljakt in code: `Biljakt.xcodeproj`, `Biljakt/` folder, target/module Biljakt, `BiljaktApp`, `AppStyle`, `BiljaktLogo`. Added "En produkt av Ibrax AB" and copyright © 2026 Ibrax AB.
- 2026-11-01 – Added `.github/workflows/deploy-api.yml` for one-click API deploys from GitHub (secrets must be added by the user).
- 2026-11-01 – Renamed to **Biljakt** (display name, all UI text, new icon with BILJAKT) and removed the driver rating: no `GalenLevel`, "Mina betyg" is now "Mina bilar", `Score` nullable (`schema-4-biljakt.sql`). Guessing made more sensitive (small text, top 3 OCR candidates, classifier threshold 0.1). Upload zip: project files `platerater/Biljakt-API-upload-2026-11-01.zip`. Kind/brand not being saved was traced to the server still running the old API (check: `/api/friends` gives 401 on the new API, 404 on the old).
- 2026-11-01 – `schema-3-friends.sql` run on `db_a30625_platerater` (all four tables exist). Next: upload the new API, then build in Xcode.
- 2026-11-01 – Brand hunt and photo guessing: ratings can have a brand (`CarBrand`, `Ratings.Brand`, 19 brands), Jakt has a Märken tab, brands count on the leaderboard. When a photo is added, `CarGuesser` guesses color, brand and kind on the phone and warns on a mismatch. A real make/model recognizer would need a Core ML model or a paid cloud API; not done.

- 2026-11-01 – Friends: new Tävla tab, add friends by Google e-mail, accept/decline, leaderboard by hunt points (`FriendsView.swift`, `/api/friends`, `schema-3-friends.sql`). Friends see first name, points, and which colors/kinds were found only.
- 2026-11-01 – Car-kind hunt: ratings can have a kind of car (`CarKind`, `Ratings.Kind`); Färgjakt tab renamed Jakt with Färger/Biltyper; points via `HuntScore`.
- 2026-11-01 – Private ratings: `GET /api/plates/{plate}` returns only your own rating; the app no longer shows average, count or "Alla betyg".
- 2026-11-01 – Legal review written (see above).
- 2026-10-30 – Galen rebrand, colors, photos, Mina betyg, color hunt, plate OCR, app icon and splash (PR #1).
- 2026-10-27 – API deployed to SmarterASP; first Xcode build succeeded.
