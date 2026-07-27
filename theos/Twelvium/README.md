# Twelvium Theos application package

This is a Theos application port scaffold for the cleaned source tree. It
packages `/Applications/Twelvium.app` into a rootful iOS 6 `.deb`; it does not
build or install a tweak, daemon, launch agent, or call bridge.

## First build in the legacy VM

1. Install Theos and an iOS 6-compatible SDK/toolchain, then set `THEOS` if it
   is not `/Users/anazerka/theos`. Theos does not support spaces in paths: put
   this tree in a directory such as `~/Twelvium_Public`, not `Twelvium_Public 2`.
2. At repository root, copy `config.h.example` to `config.h` and fill in your
   own API credentials.
3. From this directory run `make manifest`. It exports the exact Xcode
   `Telegraph` Sources build phase to `Sources.mk`.
   Check `MissingSources.txt`; this public snapshot currently has six dangling
   Xcode build-file references and one absent TL source, so those must be
   restored from a trusted source or removed from the original target.
4. Rebuild the required armv7 archives, especially
   `thirdparty/TgVoipWebrtcIOS6/lib/libTgVoipWebrtcIOS6Core.a`. Do not use a
   binary copied from an untrusted IPA/DEB.
5. Run `make package FINALPACKAGE=1`.

The first failures after this point are expected dependency-porting failures:
the original app depended on separate Xcode static-library targets
(`LegacyComponents`, `MtProtoKit`, `SSignalKit`, `LegacyDatabase`, and
`libtgvoip`). Port those as Theos static-library subprojects or supply clean,
locally built armv7 archives before attempting a release package.

The Theos manifest deliberately excludes Watch, Siri, Share extensions,
HockeySDK, the removed call bridge, and external build products.
