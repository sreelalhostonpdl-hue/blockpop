# AdMob integration – exact remaining steps

**Status: adapter complete, native SDK bridge NOT included.** `scripts/AdManager.gd` contains the
full policy layer (test/production ID switch, frequency capping, "never during gameplay",
"rewarded only after a completed view", consent hook). No ads are shown and nothing is faked
until you complete the steps below, because the AdMob SDK is a native Android library that
cannot be built or tested in this environment.

1. **Create AdMob account**, register the app, create 3 ad units (banner, interstitial, rewarded).
2. **Install an AdMob plugin for Godot 4** (Asset Library / GitHub "godot-admob-android" style
   plugin that supports Godot 4.3+, banner/interstitial/rewarded and Google UMP). Enable it in
   *Project > Project Settings > Plugins*.
3. **Project > Install Android Build Template**, then in the Android export preset keep
   *Gradle Build > Use Gradle Build* enabled (already set in `export_presets.cfg`).
4. **Put your AdMob App ID** in the plugin's configuration (it is written to AndroidManifest
   as `com.google.android.gms.ads.APPLICATION_ID`). Using the wrong/missing ID crashes at launch.
5. **Fill in the `_backend_*` functions** in `scripts/AdManager.gd` using the plugin API:
   - `_backend_initialize`: detect plugin, init SDK, set `backend_ready = true`.
   - `_backend_request_consent_then_init`: UMP consent request → set `privacy_options_required`.
   - `_backend_show/hide_banner`: anchored adaptive banner at bottom (home screen only).
   - `_backend_interstitial_ready/_show_interstitial`: call `done.call()` on dismiss *or* failure; preload next.
   - `_backend_rewarded_ready/_show_rewarded`: `done.call(true)` ONLY from the "user earned reward" callback.
6. **Production IDs:** edit `PROD_IDS` at the top of `AdManager.gd` and set `USE_TEST_ADS := false`
   for the release build only. Keep test IDs while developing (clicking real ads on your own
   account can get it banned).
7. Test on a real device: banner on home, interstitial after every 3rd finished game (≥120 s apart),
   rewarded button appears on Game Over only when an ad is loaded, consent dialog for EEA/UK
   (use UMP debug geography).
8. If targeting children / mixed audience, configure `tagForChildDirectedTreatment` /
   `tagForUnderAgeOfConsent` and review Google Play Families policy.
