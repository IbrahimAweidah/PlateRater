# Galen (repo PlateRater)

**Galen**: a funny, kid-friendly Swedish iOS app (SwiftUI, iOS 17) for rating how crazy drivers are by Swedish license plate, plus an ASP.NET Core 8 API that stores the ratings.

## Layout

- `Galen/` – the iOS app (target and scheme `Galen`, entry point `GalenApp.swift` with a splash screen). Open `Galen.xcodeproj` in Xcode to build and run. The GitHub repo, API and database tables keep the PlateRater name.
  - `Assets.xcassets` – `AppIcon` and `GalenLogo` (same 1024px image), pink `AccentColor`.
  - `AuthManager.swift` – Google sign-in (GoogleSignIn-iOS 8.x via Swift Package Manager).
  - `APIClient.swift` – calls the API with the Google ID token as a bearer token.
  - `RatingStore.swift`, `PlateDetailView.swift`, `ContentView.swift` (tabs: Spana, Mina betyg, Färgjakt), `MyRatingsView.swift`, `ColorHuntView.swift`, `SignInView.swift` – UI and state.
  - `PlateScanner.swift` – reads the plate from a photo on the device (Apple Vision text recognition, no server, free). Used by "Fota skylten" on the Spana tab; the photo is then attached to the rating.
  - `Theme.swift` – Galen colors, `GalenLevel` (1 🐌 Snigelfart … 5 🤪 Galen förare), `CarColor` (keys must match `CarColors` in the API), `SpotterRank`.
  - UI text is Swedish. Bundle ID stays `com.ibrahimaweidah.PlateRater` (Google OAuth client is tied to it); display name is Galen.
  - `Config.xcconfig` – `GOOGLE_CLIENT_ID`, `GOOGLE_REVERSED_CLIENT_ID`, `API_BASE_URL`, fed into `Info.plist`. In xcconfig `//` starts a comment, so URLs are written `https:/$()/host/`.
- `PlateRaterAPI/` – ASP.NET Core 8 minimal API (`Program.cs`, `AppDb.cs`), EF Core with SQL Server.
  - `schema.sql` – creates `PlateRaterUsers` and `PlateRaterRatings`. Already run on the production database.
  - `schema-2-galen.sql` – adds `Color` to ratings and the `PlateRaterPhotos` table. Must run before deploying the Galen API.
  - `appsettings.json` – connection string has a `YOUR-DB-PASSWORD` placeholder. Never commit the real password.
- `SETUP.md` – step-by-step setup guide.

## How it fits together

- The app signs in with Google and sends the ID token on every request. The API validates it against Google's keys (JwtBearer, authority `https://accounts.google.com`, audience = the iOS client ID in `Google:ClientIds`).
- Endpoints: `GET /api/plates/{plate}`, `PUT /api/plates/{plate}/rating` (`{score, comment, color}`), `DELETE /api/plates/{plate}/rating`, `PUT|GET|DELETE /api/plates/{plate}/rating/photo` (raw JPEG/PNG body, max 3 MB), `GET /api/me/ratings`. One rating per Google account per plate. Other users' names, emails and photos are never returned.

## Where things run

- API: SmarterASP.NET site at https://ibrahimawe-001-site5.ftempurl.com/ (temporary SmarterASP address; https works). Deployed by uploading the output of `dotnet publish -c Release` via FTP. The deployed copy with the real password lives in the git-ignored `PlateRaterAPI/publish/` folder.
- Database: SmarterASP MSSQL `DB_A30625_ibrahimawe` on `sql6018.site4now.net`, shared with the Ibrax_1 website.
- Google Cloud project "Ibrax": iOS OAuth client `619027614244-cnrk7d54uq6ah0i55kbooandipf6dl49.apps.googleusercontent.com`, bundle ID `com.ibrahimaweidah.PlateRater`. Consent screen is in Testing; only listed test users can sign in.

## Status

- The original API is deployed and the first Xcode build succeeded.
- Galen update (colors, photos, Mina betyg, Färgjakt): not compiled in Xcode yet; needs `schema-2-galen.sql` run, then API re-upload, then an Xcode build.
- No free API gives Swedish vehicle data (make/model/color) by plate; Transportstyrelsen and the commercial options (biluppgifter.se, car.info, tic.io, minbilkoll.se) need an agreement or a paid plan.
