# Spotify6 - riff (SecondTrack/riff) ported to the iPhone 3GS (iOS 6.1.6, armv7). Theos, installed as a user-app IPA.
TARGET := iphone:clang:9.3:6.0
ARCHS  := armv7
PACKAGE_FORMAT := ipa

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Spotify6

Spotify6_FILES  = $(wildcard music/App/*.m) $(wildcard music/UI/*.m) $(wildcard music/Spot/*.m) $(wildcard music/Spot/*.c)
Spotify6_FRAMEWORKS = UIKit CoreGraphics Foundation QuartzCore AVFoundation AudioToolbox Security MediaPlayer SystemConfiguration
MBED = $(THEOS_PROJECT_DIR)/vendor/mbedtls/out/ios
Spotify6_CFLAGS  = -fobjc-arc -O2 -Wall -Werror \
	-Werror=unguarded-availability -Werror=partial-availability -Wno-deprecated-module-dot-map \
	-Imusic/App -Imusic/UI -Imusic/Spot -Ivendor/stb -I$(MBED)/include -include $(MBED)/include/mbedtls_ios6_predef.h
Spotify6_LDFLAGS  = -L$(MBED)/lib -lmbedtls -lmbedx509 -lmbedcrypto -ObjC
Spotify6_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/ent.plist

ifneq ($(MAKECMDGOALS),clean)
ifeq ($(wildcard $(MBED)/lib/libmbedtls.a),)
$(error build mbedTLS first: vendor/mbedtls/build.sh)
endif
endif

include $(THEOS_MAKE_PATH)/application.mk
