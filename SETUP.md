# Biljakt setup

Biljakt is an iOS app (`Biljakt/`, open `Biljakt.xcodeproj`) and an ASP.NET Core 8 API (`BiljaktAPI/`) on SmarterASP.NET with an MSSQL database. A product of Ibrax AB.

## Database

- New, empty database: run `BiljaktAPI/schema.sql` in Web SQL Manager (SmarterASP Control Panel > Databases > MSSQL).
- The production database `db_a30625_platerater` had the old `PlateRater*` tables. Run `BiljaktAPI/migrate-to-biljakt.sql` once to rename them to `Biljakt*`.

## API

Deploys itself: every push that changes `BiljaktAPI/` on `main` or the Biljakt branch runs the GitHub Actions workflow **Deploy API to SmarterASP**. It builds the API, takes the site offline with `app_offline.htm`, uploads over FTPS, never touches the server's `appsettings.json`, and checks that `/api/friends` answers 401. It needs the repository secrets `FTP_HOST`, `FTP_USER`, `FTP_PASSWORD` and `FTP_DIR`. You can also start it by hand under Actions > Deploy API to SmarterASP > Run workflow.

The server's `appsettings.json` holds the real connection string (named `Biljakt`, or the older name `PlateRater`) and `Google:ClientIds`. Never commit the real password.

## App

1. `git pull`, open `Biljakt.xcodeproj`.
2. Signing & Capabilities: pick your Team.
3. Pick your iPhone and press Cmd-R. The first time, turn on Developer Mode on the phone and trust the developer.

`Biljakt/Config.xcconfig` holds `GOOGLE_CLIENT_ID`, `GOOGLE_REVERSED_CLIENT_ID` and `API_BASE_URL` (written `https:/$()/host/`, because `//` starts a comment in xcconfig).

## What the app does

- Spana: type or photograph a plate. Pick color, kind and brand; Biljakt guesses them from the photo on the phone and warns if the photo doesn't match.
- Mina bilar: everything you have found. Jakt: color, kind and brand hunts with points. Tävla: add friends by Google e-mail and compete on a leaderboard.
- Everything is private. Friends only see your first name, your points and which colors, kinds and brands you found.
