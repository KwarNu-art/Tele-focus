TARGET := iphone:clang:latest:12.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES := SpringBoard Telegraph

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := TeleFocus

TeleFocus_FILES := Sources/Tweak.xm Sources/TFEngine.m Sources/TFPrefs.m
TeleFocus_CFLAGS := -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
TeleFocus_FRAMEWORKS := UIKit Foundation QuartzCore CoreGraphics
TeleFocus_PRIVATE_FRAMEWORKS :=

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Telegraph 2>/dev/null; killall -9 SpringBoard 2>/dev/null; true"
