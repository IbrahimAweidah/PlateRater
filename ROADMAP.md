# Biljakt roadmap

Planned work for future releases, decided with the owner (Ibrax AB) on 2026-11-01. Keep this file up to date when something is done or changes.

## Before App Store launch (must)

- [ ] Apple Developer Program for Ibrax AB (applied 2026-11-01, waiting for Apple's check of signing authority). Then switch Sign in with Apple back on (`AuthManager.appleSignInEnabled = true`, add the capability in Xcode) and start TestFlight (guide: https://claude.ai/artifact/BtyrRSvq7ne3Kkow3xy35Y).
- [ ] Delete account in the app (Apple requires it): API endpoint that removes the user, ratings, photos and friendships; button in the profile menu.
- [ ] Privacy policy and terms on a web page, linked in the app (draft, then a lawyer reviews).
- [ ] Real brand logos off (`BrandBadge.useRealLogos = false`) unless the brands give permission.
- [ ] 13-year age limit and a "never use while driving" warning.
- [ ] Google OAuth consent screen from Testing to published.
- [ ] Own domain (check biljakt.se) with its own certificate for the API and the policy page.
- [ ] App Store Connect: screenshots, description, age rating, App Privacy answers.

## Making money

Principle: Biljakt stays free to download. No third-party ads and never selling data (kids' app, privacy is a selling point).

1. **Biljakt Familj (one-time unlock, about 49–79 kr)** via StoreKit. The basic hunt stays free. The unlock adds extra hunts (rare cars, electric cars, veteran cars), family leagues with more friends, stats and badges. Apple keeps 15% (Small Business Program).
2. **Seasonal hunt packs (about 19–29 kr each):** Sommarlovsjakten, Roadtrip-paketet, Julafton-jakten. Aimed at families on car trips.
3. **Sponsored hunts:** a car brand, dealer, insurance company or fuel chain (e.g. Circle K, Preem) sponsors a hunt ("Hitta 10 Volvo XC40"). Also the clean way to get permission for real brand logos.
4. **Not doing:** third-party ads (GDPR issues for children, not allowed in Apple's Kids category, low revenue) and selling data.

Every purchase needs a parental gate (a question only an adult can answer), as Apple requires for apps aimed at kids.
