# PlateRater

iOS app (SwiftUI, iOS 17) for rating drivers by Swedish license plate, plus an ASP.NET Core 8 API that stores the ratings.

## Layout

- `PlateRater/` – the iOS app. Open `PlateRater.xcodeproj` in Xcode to build and run.
  - `AuthManager.swift` – Google sign-in (GoogleSignIn-iOS 8.x via Swift Package Manager).
  - `APIClient.swift` – calls the API with the Google ID token as a bearer token.
  - `RatingStore.swift`, `PlateDetailView.swift`, `ContentView.swift`, `SignInView.swift` – UI and state.
  - `Config.xcconfig` – `GOOGLE_CLIENT_ID`, `GOOGLE_REVERSED_CLIENT_ID`, `API_BASE_URL`, fed into `Info.plist`. In xcconfig `//` starts a comment, so URLs are written `https:/$()/host/`.
- `PlateRaterAPI/` – ASP.NET Core 8 minimal API (`Program.cs`, `AppDb.cs`), EF Core with SQL Server.
  - `schema.sql` – creates `PlateRaterUsers` and `PlateRaterRatings`. Already run on the production database.
  - `appsettings.json` – connection string has a `YOUR-DB-PASSWORD` placeholder. Never commit the real password.
- `SETUP.md` – step-by-step setup guide.

## How it fits together

- The app signs in with Google and sends the ID token on every request. The API validates it against Google's keys (JwtBearer, authority `https://accounts.google.com`, audience = the iOS client ID in `Google:ClientIds`).
- Endpoints: `GET /api/plates/{plate}`, `PUT /api/plates/{plate}/rating` (`{score, comment}`), `DELETE /api/plates/{plate}/rating`. One rating per Google account per plate. Other users' names and emails are never returned.

## Where things run

- API: SmarterASP.NET site at https://ibrahimawe-001-site5.ftempurl.com/ (temporary SmarterASP address; https works). Deployed by uploading the output of `dotnet publish -c Release` via FTP. The deployed copy with the real password lives in the git-ignored `PlateRaterAPI/publish/` folder.
- Database: SmarterASP MSSQL `DB_A30625_ibrahimawe` on `sql6018.site4now.net`, shared with the Ibrax_1 website.
- Google Cloud project "Ibrax": iOS OAuth client `619027614244-cnrk7d54uq6ah0i55kbooandipf6dl49.apps.googleusercontent.com`, bundle ID `com.ibrahimaweidah.PlateRater`. Consent screen is in Testing; only listed test users can sign in.

## Status

- The API is deployed and responds.
- The Swift code has not been compiled yet. Next step: build in Xcode and fix any errors, then sign in and rate a plate end to end.
