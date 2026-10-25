# PlateRater: database and Google sign-in setup

The app now signs in with Google and stores ratings on your server. There are four steps to switch it on.

## 1. Create the iOS sign-in client in Google Cloud

1. Open https://console.cloud.google.com/apis/credentials. You can reuse the project you already use for Ibrax's Google login.
2. Click **Create credentials > OAuth client ID** and choose **iOS** as the application type.
3. Enter the bundle ID `com.ibrahimaweidah.PlateRater` and click **Create**.
4. Copy the **Client ID** and the **iOS URL scheme** that Google shows you.
5. If the OAuth consent screen is in **Testing** mode, add every Google account that should be able to sign in as a test user.

## 2. Create the tables in your SmarterASP.NET database

1. In the SmarterASP.NET control panel, go to **Databases > MSSQL** and open **Web SQL Manager** for `DB_A30625_ibrahimawe`. You can also connect with Azure Data Studio or SSMS.
2. Run `PlateRaterAPI/schema.sql`. It adds two new tables, `PlateRaterUsers` and `PlateRaterRatings`, and doesn't change your existing tables.

## 3. Publish the API to SmarterASP.NET

1. Install the .NET 8 SDK on your Mac: https://dotnet.microsoft.com/download/dotnet/8.0
2. Build the API:
   ```
   cd ~/Developer/PlateRater/PlateRaterAPI
   dotnet publish -c Release -o publish
   ```
3. Edit `publish/appsettings.json`:
   - Replace `YOUR-DB-PASSWORD` with your database password.
   - Replace `YOUR-IOS-CLIENT-ID.apps.googleusercontent.com` with the Client ID from step 1.

   Keep the password only in the `publish` copy so it never ends up in GitHub.
4. In the SmarterASP.NET control panel, add a website or subdomain for the API (for example `api.yourdomain.com`), and set it to run **ASP.NET Core / .NET 8**.
5. Upload everything inside the `publish` folder to that site's root, using FTP, Web Deploy, or the File Manager.
6. Turn on SSL for the site. iOS only connects to `https://` addresses, and SmarterASP.NET offers a free certificate for a domain you own.
7. Open `https://YOUR-API-ADDRESS/` in a browser. You should see **PlateRater API is running.**

## 4. Point the app at Google and the API

1. Open `PlateRater/Config.xcconfig` and fill in:
   - `GOOGLE_CLIENT_ID`: the Client ID from step 1.
   - `GOOGLE_REVERSED_CLIENT_ID`: the iOS URL scheme from step 1.
   - `API_BASE_URL`: your API address. Keep the `https:/$()/` part exactly as written, because xcconfig treats `//` as the start of a comment.
2. Open `PlateRater.xcodeproj`. Xcode downloads the GoogleSignIn package the first time.
3. Run the app. It shows a Google sign-in screen first. After you sign in, ratings load from and save to the server.

## How it works

- The app gets a Google ID token from Google's sign-in SDK and sends it with every request.
- The API checks the token's signature against Google's keys and checks that it was issued for your iOS client ID. Requests without a valid token get a 401.
- On first sign-in, each Google account gets a row in `PlateRaterUsers`. Each account has one rating per plate, and rating the same plate again updates it.
- Other people's ratings show only a score, a comment, and a date. Names and emails are never sent to the app.

Your original app files are backed up in `_backup-before-backend/`.
