# Galen (repo PlateRater)

**Galen**: a funny, kid-friendly Swedish iOS app (SwiftUI, iOS 17) for rating how crazy drivers are by Swedish license plate, plus an ASP.NET Core 8 API that stores the ratings.

## Layout

- `Galen/` – the iOS app (target and scheme `Galen`, entry point `GalenApp.swift` with a splash screen). Open `Galen.xcodeproj` in Xcode to build and run. The GitHub repo, API and database tables keep the PlateRater name.
  - `Assets.xcassets` – `AppIcon` and `GalenLogo` (same 1024px image), pink `AccentColor`.
  - `AuthManager.swift` – Google sign-in (GoogleSignIn-iOS 8.x via Swift Package Manager).
  - `APIClient.swift` – calls the API with the Google ID token as a bearer token.
  - `RatingStore.swift`, `PlateDetailView.swift`, `ContentView.swift` (tabs: Spana, Mina betyg, Jakt, Tävla), `MyRatingsView.swift`, `ColorHuntView.swift` (Jakt: colors, car kinds and brands), `FriendsView.swift` (friends and leaderboard), `SignInView.swift` – UI and state.
  - `PlateScanner.swift` – reads the plate from a photo on the device (Apple Vision text recognition, no server, free). Used by "Fota skylten" on the Spana tab; the photo is then attached to the rating.
  - `CarGuesser.swift` – guesses color (car cut out with Vision foreground mask, pixels vote for a `CarColor`), brand (text on the car via Vision OCR) and kind (Vision image classifier) from the rating photo, on the device. Fills empty fields and warns when the photo doesn't match what the user picked.
  - `Theme.swift` – Galen colors, `GalenLevel` (1 🐌 Snigelfart … 5 🤪 Galen förare), `CarColor`, `CarKind` and `CarBrand` (keys must match `CarColors`, `CarKinds` and `CarBrands` in the API), `HuntScore`, `SpotterRank`.
  - UI text is Swedish. Bundle ID stays `com.ibrahimaweidah.PlateRater` (Google OAuth client is tied to it); display name is Galen.
  - `Config.xcconfig` – `GOOGLE_CLIENT_ID`, `GOOGLE_REVERSED_CLIENT_ID`, `API_BASE_URL`, fed into `Info.plist`. In xcconfig `//` starts a comment, so URLs are written `https:/$()/host/`.
- `PlateRaterAPI/` – ASP.NET Core 8 minimal API (`Program.cs`, `AppDb.cs`), EF Core with SQL Server.
  - `schema.sql` – creates `PlateRaterUsers` and `PlateRaterRatings`. Already run on the production database.
  - `schema-2-galen.sql` – adds `Color` to ratings and the `PlateRaterPhotos` table. Must run before deploying the Galen API.
  - `schema-3-friends.sql` – adds `Kind` and `Brand` to ratings and the `PlateRaterFriendships` table. Run after schema-2, before deploying.
  - `appsettings.json` – connection string has a `YOUR-DB-PASSWORD` placeholder. Never commit the real password.
- `SETUP.md` – step-by-step setup guide.

## How it fits together

- The app signs in with Google and sends the ID token on every request. The API validates it against Google's keys (JwtBearer, authority `https://accounts.google.com`, audience = the iOS client ID in `Google:ClientIds`).
- Endpoints: `GET /api/plates/{plate}`, `PUT /api/plates/{plate}/rating` (`{score, comment, color}`), `DELETE /api/plates/{plate}/rating`, `PUT|GET|DELETE /api/plates/{plate}/rating/photo` (raw JPEG/PNG body, max 3 MB), `GET /api/me/ratings`, `GET|POST /api/friends` (`{email}`), `POST /api/friends/{id}/accept`, `DELETE /api/friends/{id}`. One rating per Google account per plate. Ratings are private: every endpoint returns only the signed-in user's own ratings, comments and photos, never anyone else's (decided 2026-11-01 after a legal review, to keep personal data about car owners from being shown to others). Friends, added by Google e-mail and accepted by the other side, see only each other's first name and which colors, kinds and brands of car they found.

## Where things run

- API: SmarterASP.NET site at https://ibrahimawe-001-site5.ftempurl.com/ (temporary SmarterASP address; https works). Deployed by uploading the output of `dotnet publish -c Release` via FTP. The deployed copy with the real password lives in the git-ignored `PlateRaterAPI/publish/` folder.
- Database: SmarterASP MSSQL `DB_A30625_ibrahimawe` on `sql6018.site4now.net`, shared with the Ibrax_1 website.
- Google Cloud project "Ibrax": iOS OAuth client `619027614244-cnrk7d54uq6ah0i55kbooandipf6dl49.apps.googleusercontent.com`, bundle ID `com.ibrahimaweidah.PlateRater`. Consent screen is in Testing; only listed test users can sign in.

## Status

- The original API is deployed and the first Xcode build succeeded.
- Galen update (colors, photos, Mina betyg, Jakt, Tävla): needs `schema-2-galen.sql` and `schema-3-friends.sql` run, then API re-upload, then an Xcode build. The friends/kinds code has not been compiled yet.
- No free API gives Swedish vehicle data (make/model/color) by plate; Transportstyrelsen and the commercial options (biluppgifter.se, car.info, tic.io, minbilkoll.se) need an agreement or a paid plan.

## Branches

- `main` – the original PlateRater app with the backend.
- `claude/project-thread-m1xtn2` (PR #1) – Galen rebrand: colors, photos, Mina betyg, color hunt, plate OCR, icon and splash.
- `claude/project-thread-y1essk` – built on PR #1: private ratings, car-kind and brand hunt, photo guessing, friends and leaderboard. Merge PR #1 first.

## Legal review (2026-11-01)

A Swedish-law review (not by a lawyer) is at https://claude.ai/artifact/SpgPu9NR3xbetS37BPqkhL. Main points and what is still open before App Store launch:

- Done: ratings, comments and photos are private (only the author sees them), because public ratings of a plate are personal data about the car owner and free text can be defamation.
- Keep it that way: never show one user's plates, ratings, comments or photos to another user, friends included.
- Still to do: privacy policy and terms (link in the app), in-app account deletion, Sign in with Apple, 13-year age limit, "never use while driving" warning, data retention, SmarterASP data processing agreement and data location, own DB user separate from Ibrax_1, a real domain with its own certificate. A lawyer should review before launch.

## Recent changes (newest first)

Keep this list up to date: add a line here whenever you change the app, the API or the database, so the next session (on any device) knows the current state.

- 2026-11-01 – Brand hunt and photo guessing: ratings can have a brand (`CarBrand`, `Ratings.Brand`, 19 brands), Jakt has a Märken tab, brands count on the leaderboard. When a photo is added, `CarGuesser` guesses color, brand and kind on the phone and warns on a mismatch. A real make/model recognizer would need a Core ML model or a paid cloud API; not done.

- 2026-11-01 – Friends: new Tävla tab, add friends by Google e-mail, accept/decline, leaderboard by hunt points (`FriendsView.swift`, `/api/friends`, `schema-3-friends.sql`). Friends see first name, points, and which colors/kinds were found only.
- 2026-11-01 – Car-kind hunt: ratings can have a kind of car (`CarKind`, `Ratings.Kind`); Färgjakt tab renamed Jakt with Färger/Biltyper; points via `HuntScore`.
- 2026-11-01 – Private ratings: `GET /api/plates/{plate}` returns only your own rating; the app no longer shows average, count or "Alla betyg".
- 2026-11-01 – Legal review written (see above).
- 2026-10-30 – Galen rebrand, colors, photos, Mina betyg, color hunt, plate OCR, app icon and splash (PR #1).
- 2026-10-27 – API deployed to SmarterASP; first Xcode build succeeded.
