export THEOS ?= /Users/anazerka/theos

# This is a rootful iOS 6 application package, not a MobileSubstrate tweak.
ARCHS = armv7
TARGET = iphone:clang:latest:6.0

APPLICATION_NAME = Tele6ram
Tele6ram_BUNDLE_NAME = Tele6ram
Tele6ram_INSTALL_PATH = /Applications
Tele6ram_FILES = $(TELE6RAM_SOURCES)
Tele6ram_RESOURCE_DIRS = ../../Telegraph/Resources ../../Telegraph/en.lproj ../../Telegraph/ru.lproj ../../Telegraph/de.lproj ../../Telegraph/es.lproj ../../Telegraph/it.lproj ../../Telegraph/ko.lproj ../../Telegraph/nl.lproj ../../Telegraph/pt.lproj ../../Telegraph/ar.lproj
Tele6ram_BUNDLE_RESOURCES = ../../Telegraph/Telegraph-Info.plist
Tele6ram_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-receiver-is-weak -Wno-conversion -DSQLITE_TEMP_STORE=2 -DSQLITE_HAS_CODEC=1 -DSQLCIPHER_CRYPTO_CC=1 -DSQLITE_ENABLE_FTS3 -DTGVOIP_USE_CUSTOM_CRYPTO -DTGVOIP_USE_AUDIO_SESSION -DTG_PUBLIC_BUILD=1
Tele6ram_CCFLAGS = -std=gnu++0x
Tele6ram_OBJCFLAGS = -include ../../submodules/LegacyComponents/LegacyComponents/LegacyComponentsIos6Compat.h
Tele6ram_CFLAGS += -I../../submodules/MtProtoKit -I../../submodules/LegacyComponents -I../../Telegraph/thirdparty/ogg -I../../thirdparty/libphonenumber.framework/Headers -I../../legacy/TelegraphKit -I../../legacy/TL -I../../legacy/TL/TL -I../../thirdparty/pop -I../../thirdparty/libbpg -I../../thirdparty/SSignalKit -I../../submodules/libtgvoip -I../../thirdparty/Lottie/lottie-ios/Classes/PublicHeaders -I../../thirdparty/Stripe -I../../Telegraph/thirdparty/opus/include -I../../thirdparty/TgVoipWebrtcIOS6/include
Tele6ram_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreFoundation CFNetwork SystemConfiguration Security MobileCoreServices AssetsLibrary AVFoundation AudioToolbox CoreMedia CoreVideo ImageIO MapKit AddressBook EventKit MessageUI MediaPlayer OpenGLES GLKit CoreMotion QuickLook Accelerate PassKit VideoToolbox
Tele6ram_LIBRARIES = c++ z sqlite3 icucore crypto TgVoipWebrtcIOS6Core
Tele6ram_LDFLAGS = -ObjC -L../../thirdparty/TgVoipWebrtcIOS6/lib -L../../submodules/MtProtoKit/openssl/iOS

-include Sources.mk

ifeq ($(strip $(TELE6RAM_SOURCES)),)
$(error Run `make manifest` once to export the Telegraph source list.)
endif

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/application.mk

.PHONY: manifest verify-layout

manifest:
	@ruby generate_manifest.rb

verify-layout:
	@test -f ../../config.h || (echo "Missing ../../config.h; copy config.h.example first."; exit 1)
	@test -f ../../thirdparty/TgVoipWebrtcIOS6/lib/libTgVoipWebrtcIOS6Core.a || (echo "Missing rebuilt TgVoipWebrtcIOS6 armv7 archive."; exit 1)

before-all:: verify-layout
