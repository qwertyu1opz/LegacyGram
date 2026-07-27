# Twelvium

This public source snapshot contains no signing identities, provisioning profiles,
private API credentials, private user allowlists, or private telemetry endpoints.

# How to build
1. Clone this repository.
2. Create a local `config.h` file with your own Telegram API credentials:
    ```
    #define SETUP_API_ID(apiId) apiId = 12345;
    #define SETUP_API_HASH(apiHash) apiHash = @"replace-with-your-own-api-hash";
    ```
   Do not commit this file; it is excluded by `.gitignore`.
   A safe starting template is included as `config.h.example`.
3. Initialize any required submodules if you publish this snapshot as a Git repository.
4. Replace the neutral `com.example.Twelvium` bundle identifiers and configure your own Apple signing team, entitlements, merchant ID, provisioning profile and APNs credentials.
5. Configure a Dropbox app key only if you need the Dropbox picker integration.
6. Rebuild the omitted Opus, OpenSSL, libbpg and HockeySDK binaries from source (or supply clean equivalents).
7. Open `Telegram.xcworkspace` in Xcode.

The public settings UI contains no premium/paid-feature gate. Private crash and
performance upload endpoints are disabled in this public snapshot. You must
provide your own infrastructure for optional services such as APNs.

See `SECURITY_AND_BUILD.md` for the public-build security boundary and the
Xcode/iOS 6.1 build procedure.

# Credits
[Igor igkuzm Semetsov](https://github.com/igkuzm) - Fix outdated client error
IOvanQ - provided a remote PC for building and testing
