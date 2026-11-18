# Google Play release guide

## 1. Before building
- Change `package/unique_name` in `export_presets.cfg` (or Export dialog) from `com.yourcompany.blockpop`.
- Host a privacy policy (see `docs/PRIVACY_POLICY_TEMPLATE.md`) and set `PRIVACY_POLICY_URL` in `scripts/ui/SettingsScreen.gd`.
- Complete `docs/ADMOB_INTEGRATION.md` and switch to production ad IDs.
- Bump `version/code` (integer, must increase every upload) and `version/name`.

## 2. Build signed AAB
1. Godot 4.3+: *Editor > Manage Export Templates* → install. *Editor Settings > Export > Android*: set Java SDK + Android SDK paths.
2. Create an upload keystore:
   `keytool -genkeypair -v -keystore blockpop-upload.jks -alias blockpop -keyalg RSA -keysize 2048 -validity 10000`
   (keep it safe; never commit it).
3. *Project > Install Android Build Template*.
4. *Project > Export > Android Release (AAB)*: set Release keystore/user/password, then **Export Project** → `build/blockpop-release.aab`.
5. Enroll in **Play App Signing** when creating the app in Play Console and upload the AAB to Internal testing first.

## 3. Store listing requirements
512×512 icon (`assets/icons/icon_512.png`), 1024×500 feature graphic, ≥2 phone screenshots, short (80) and full (4000) description, content rating questionnaire, target audience (13+ simplest when using ads), Ads declaration = "Yes, contains ads".

## 4. Data safety checklist (verify against your final SDK versions)
| Item | Answer |
|---|---|
| Data collected | With AdMob: **Device or other IDs** (advertising ID), **App activity / diagnostics / approximate location (IP-derived)** collected by Google Mobile Ads SDK |
| Purpose | Advertising, analytics, fraud prevention |
| Shared with third parties | Yes (Google AdMob) |
| Data encrypted in transit | Yes |
| Deletion request | Game stores only local data (scores/settings on device); ad data is governed by Google |
| Personal data collected by the game itself | None (no accounts, no servers) |
| Consent (EEA/UK) | Google UMP, see AdManager |
Re-check the form whenever you add SDKs (analytics, crash reporting, etc.).
