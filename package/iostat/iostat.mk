################################################################################
#
# iostat
#
################################################################################

IOSTAT_VERSION = 2.2
IOSTAT_SITE = http://www.linuxinsight.com/files
IOSTAT_LICENSE = GPL
IOSTAT_LICENSE_FILES = LICENSE

define IOSTAT_BUILD_CMDS
	$(MAKE) -C $(@D) $(TARGET_CONFIGURE_OPTS)
endef

define IOSTAT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(IOSTAT_DIR)/iostat $(IOSTAT_TARGET_DIR)/usr/bin/iostat
endef

$(eval $(generic-package))
