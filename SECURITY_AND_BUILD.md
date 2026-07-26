# Clean public iOS 6 build

This tree is an Xcode application project, not an Xposed/Theos tweak. The
entry workspace is `Telegram.xcworkspace`; the main application target is
`Telegraph`. Its deployment target is iOS 6.0, so it is suitable for an iOS
6.1 device once it is signed with a compatible Apple toolchain and profile.

## Changes made for the public build

- Removed the `Premium` settings entry and its locked-feature UI from
  `TGAccountSettingsController`.
- Removed the account-gating messaging attached to that UI.
- Removed the local HTTP call bridge and its Python helper. Call keys, TURN
  credentials and signaling data now never leave the native call runtime for a
  local sidecar process.
- Removed HockeySDK initialization and the linked Hockey crash/update bundle.
- Disabled Stripe SDK analytics, including its `q.stripe.com` telemetry path.
- Kept APNs disabled unless a maintainer supplies their own APNs credentials
  and server infrastructure. This prevents a public client from registering
  device tokens with an unknown service.
- The public configuration contains no private allowlist, telemetry endpoint,
  signing identity, API credentials, or embedded build products.

Telegram Payments and Stripe files are historical Telegram client code for bot
invoices. Their presence alone is not evidence of a payment wall or credential
stealer. Do not remove the generated MTProto payment schema blindly: it is part
of the protocol layer and may be required to parse server objects.

## Local build steps

1. Install the full Xcode application and select it as the active developer
   directory. Command Line Tools alone cannot open or build iOS targets.
2. Copy `config.h.example` to `config.h` and enter API credentials belonging to
   your own Telegram application. Keep that file private.
3. Open `Telegram.xcworkspace` in Xcode and select the `Telegraph` scheme.
4. Set a unique bundle identifier and an Apple signing team. The checked-in
   identifier is deliberately a neutral placeholder.
5. Rebuild or replace the omitted clean binaries listed in
   `PUBLIC_BUILD_NOTES.md` before attempting an archive.
6. Test login, messaging, media and background transport on a dedicated iOS
   6.1 device before distributing anything.

## Explicit non-goals

This snapshot cannot be made operational simply by changing a flag: its API
credentials, APNs service, signing assets and some binary dependencies were
intentionally removed. No private credentials or a third-party notification
endpoint should be copied back into a public build.

## Static audit result

The public source was searched for known exfiltration patterns (webhooks,
pastebins, tunnels, clipboard reads, keylogging APIs, dynamic library loading,
and process execution). No such app-side path was found after the removals
above. The remaining contact, camera, photo and document access belongs to
Telegram features and remains user-initiated.

This is a source audit, not a warranty for a binary obtained from elsewhere.
Build only from this tree, with locally rebuilt dependencies, and inspect the
final IPA/DEB before distribution. Do not package host-side artifacts such as
`thirdparty/sqlcipher/.libs` or any external call-bridge helper.
