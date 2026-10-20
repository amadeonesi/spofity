# Spofity - native armv7 build for iOS 5.0-6.1.6 on Debian/Ubuntu.
# Toolchain: ios5-clang + arm-apple-darwin11-ld + iPhoneOS5.0.sdk (see docs/IOS5-Guide-Debian.md).
# The source is ARC; compile with -fobjc-arc and link WITHOUT -fobjc-arc so clang does not
# demand the Xcode-only libarclite archive. The iOS 5 libobjc already exports the ARC runtime.
TOOLCHAIN ?= $(HOME)/ios-toolchain
CC        := $(TOOLCHAIN)/bin/ios5-clang
SDK       := $(TOOLCHAIN)/SDKs/iPhoneOS5.0.sdk
MBED      := vendor/mbedtls/out/ios

APP       := build/Spofity
BIN       := Spofity
BUNDLE    := Payload/$(BIN).app
IPA       := Spofity.ipa

SRC_M     := $(wildcard music/App/*.m) $(wildcard music/UI/*.m) $(wildcard music/Spot/*.m)
SRC_C     := $(wildcard music/Spot/*.c)
OBJ       := $(patsubst %.m,build/obj/%.o,$(SRC_M)) $(patsubst %.c,build/obj/%.o,$(SRC_C))

CFLAGS    := -fobjc-arc -O2 -Wall -Werror \
             -Werror=unguarded-availability -Werror=partial-availability \
             -Wno-deprecated-module-dot-map -Wno-unused-command-line-argument \
             -Imusic/App -Imusic/UI -Imusic/Spot -Ivendor/stb -I$(MBED)/include \
             -include $(MBED)/include/mbedtls_ios6_predef.h \
             -include music/App/MMCompat.h -DTHEOS_LEAN_AND_MEAN \
             -MMD -MP
CFLAGS_C  := -O2 -Wall -Werror -Wno-unused-command-line-argument -Imusic/Spot -MMD -MP

ifeq ($(DEBUG),1)
CFLAGS    += -DDEBUG
endif
FRAMEWORKS:= -framework UIKit -framework CoreGraphics -framework Foundation -framework QuartzCore \
             -framework AVFoundation -framework AudioToolbox -framework Security -framework MediaPlayer \
             -framework SystemConfiguration
LDFLAGS   := -L$(MBED)/lib -lmbedtls -lmbedx509 -lmbedcrypto -ObjC -Wl,-flat_namespace

ifneq ($(MAKECMDGOALS),clean)
ifeq ($(wildcard $(MBED)/lib/libmbedtls.a),)
$(error build mbedTLS first: vendor/mbedtls/build.sh)
endif
endif

all: $(APP)

$(APP): $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) -o $@ $^ $(LDFLAGS) $(FRAMEWORKS)

build/obj/%.o: %.m
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

build/obj/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_C) -c $< -o $@

bundle: $(APP)
	@rm -rf $(BUNDLE)
	@mkdir -p $(BUNDLE)
	cp $(APP) $(BUNDLE)/$(BIN)
	cp -R Resources/. $(BUNDLE)/
	printf "APPL????" > $(BUNDLE)/PkgInfo
	chmod 0755 $(BUNDLE)/$(BIN)
	ldid -Sentitlements.xml $(BUNDLE)/$(BIN)

ipa: bundle
	@rm -f $(IPA)
	@zip -qry $(IPA) Payload
	@echo "Built: $(PWD)/$(IPA)"

clean:
	@rm -rf build Payload $(IPA)

.PHONY: all bundle ipa clean

-include $(OBJ:.o=.d)
