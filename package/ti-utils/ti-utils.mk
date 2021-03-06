################################################################################
#
# ti-utils
#
################################################################################

TI_UTILS_VERSION = 06dbdb2727354b5f3ad7c723897f40051fddee49
TI_UTILS_SITE = $(call github,gxk,ti-utils,$(TI_UTILS_VERSION))
TI_UTILS_DEPENDENCIES = libnl
TI_UTILS_LICENSE = BSD-3c
TI_UTILS_LICENSE_FILES = COPYING

define TI_UTILS_BUILD_CMDS
	$(MAKE1) NFSROOT="$(STAGING_DIR)" \
		CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -I$(STAGING_DIR)/usr/include/libnl3" \
		LIBS="-lnl-3 -lnl-genl-3 -lpthread -lm" -C $(@D) all
endef

define TI_UTILS_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/calibrator \
		$(TI_UTILS_TARGET_DIR)/usr/bin/calibrator
	$(INSTALL) -m 0755 -D $(@D)/scripts/go.sh \
		$(TI_UTILS_TARGET_DIR)/usr/share/ti-utils/scripts/go.sh

	cp -r $(@D)/ini_files $(TI_UTILS_TARGET_DIR)/usr/share/ti-utils
endef

$(eval $(generic-package))
