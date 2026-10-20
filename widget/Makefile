# SpofityWidget - Mitteilungszentrum-Widget (iOS 6) für den laufenden Spofity-Titel.
# Liegt bei den System-Widgets: nur dort findet die Einstellungen-App Name und Symbol (WeeLoader-Pfade kann sie nicht öffnen).
# Läuft in SpringBoard; liest Titel/Cover über SBMediaController und steuert über dieselben Medienbefehle wie der Sperrbildschirm.
TARGET := iphone:clang:9.3:5.0
ARCHS  := armv7

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SpofityWidget
SpofityWidget_FILES = SpofityWidget.m
SpofityWidget_INSTALL_PATH = /System/Library/WeeAppPlugins
SpofityWidget_FRAMEWORKS = UIKit CoreGraphics QuartzCore
SpofityWidget_CFLAGS = -fobjc-arc -Wall -Werror -Werror=unguarded-availability -Werror=partial-availability -Wno-deprecated-module-dot-map
# Wie die App: flach linken, sonst findet dyld auf iOS 5 NSObject nicht (liegt dort in CoreFoundation, laut 9.3-SDK in libobjc)
SpofityWidget_LDFLAGS = -Wl,-flat_namespace -Wl,-not_for_dyld_shared_cache   # (liegt unter /System, sonst verweigert ld flat_namespace)

include $(THEOS_MAKE_PATH)/bundle.mk
