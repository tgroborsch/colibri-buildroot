################################################################################
#
# nanocom
#
################################################################################

NANOCOM_VERSION = 1.0
NANOCOM_SOURCE = nanocom.tar.gz
NANOCOM_SITE = http://downloads.sourceforge.net/project/nanocom/nanocom/v$(NANOCOM_VERSION)
NANOCOM_LICENSE = GPLv2+
NANOCOM_LICENSE_FILES = COPYING

# N.B. Don't strip any path components during extraction.
define NANOCOM_EXTRACT_CMDS
	gzip -d -c $(DL_DIR)/$(NANOCOM_SOURCE) | tar --strip-components=0 -C $(NANOCOM_DIR) -xf -
endef

define NANOCOM_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS)" -C $(@D)
endef

define NANOCOM_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/nanocom $(NANOCOM_TARGET_DIR)/usr/bin/nanocom
endef

$(eval $(generic-package))
