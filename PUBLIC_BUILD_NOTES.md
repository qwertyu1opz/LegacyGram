# Public snapshot notes

This directory is a privacy-sanitized source snapshot.

The following private or machine-specific material is intentionally not included:

- Telegram API credentials and local `config.h`;
- Apple certificates, private keys, provisioning profiles and signing identities;
- APNs server credentials;
- private premium-user allowlists;
- private crash/performance upload endpoints and report secrets;
- local build products, IPA/DEB packages, logs and crash reports;
- prebuilt TgVoip/WebRTC, Opus, OpenSSL, libbpg and HockeySDK binaries that contained local build paths;
- account-bound bundle, app-group, merchant and Dropbox identifiers (neutral placeholders are used where Xcode requires a value).

Rebuild the omitted WebRTC archive from the included source if that component is
required. Configure your own API credentials, signing team and notification
infrastructure before building or distributing an application.
