################################################################################
#
# busybox
#
################################################################################

BUSYBOX_VERSION = 1.23.1
BUSYBOX_SITE = http://www.busybox.net/downloads
BUSYBOX_SOURCE = busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_LICENSE = GPLv2
BUSYBOX_LICENSE_FILES = LICENSE

BUSYBOX_CFLAGS = \
	$(TARGET_CFLAGS)

BUSYBOX_LDFLAGS = \
	$(TARGET_LDFLAGS)

# Link against libtirpc if available so that we can leverage its RPC
# support for NFS mounting with BusyBox
ifeq ($(BR2_PACKAGE_LIBTIRPC),y)
BUSYBOX_DEPENDENCIES += libtirpc
BUSYBOX_CFLAGS += -I$(STAGING_DIR)/usr/include/tirpc/
# Don't use LDFLAGS for -ltirpc, because LDFLAGS is used for
# the non-final link of modules as well.
BUSYBOX_CFLAGS_busybox += -ltirpc
endif

BUSYBOX_BUILD_CONFIG = $(BUSYBOX_DIR)/.config
# Allows the build system to tweak CFLAGS
BUSYBOX_MAKE_ENV = \
	$(TARGET_MAKE_ENV) \
	CFLAGS="$(BUSYBOX_CFLAGS)" \
	CFLAGS_busybox="$(BUSYBOX_CFLAGS_busybox)"
BUSYBOX_MAKE_OPTS = \
	CC="$(TARGET_CC)" \
	ARCH=$(KERNEL_ARCH) \
	PREFIX="$(BUSYBOX_TARGET_DIR)" \
	EXTRA_LDFLAGS="$(BUSYBOX_LDFLAGS)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	CONFIG_PREFIX="$(BUSYBOX_TARGET_DIR)" \
	SKIP_STRIP=y

ifndef BUSYBOX_CONFIG_FILE
	BUSYBOX_CONFIG_FILE = $(call qstrip,$(BR2_PACKAGE_BUSYBOX_CONFIG))
endif

BUSYBOX_KCONFIG_FILE = $(BUSYBOX_CONFIG_FILE)
BUSYBOX_KCONFIG_EDITORS = menuconfig xconfig gconfig
BUSYBOX_KCONFIG_OPTS = $(BUSYBOX_MAKE_OPTS)

#~ define BUSYBOX_PERMISSIONS
#~ 	/bin/busybox                     f 4755 0  0 - - - - -
#~ 	/usr/share/udhcpc/default.script f 755  0  0 - - - - -
#~ endef

# If mdev will be used for device creation enable it and copy S10mdev to /etc/init.d
ifeq ($(BR2_ROOTFS_DEVICE_CREATION_DYNAMIC_MDEV),y)
define BUSYBOX_INSTALL_MDEV_SCRIPT		
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/mdev.init \
		$(BUSYBOX_TARGET_DIR)/etc/init.d/mdev
		
	$(BUSYBOX_FAKEROOT) $(INSTALL) -d -m 0755 $(BUSYBOX_TARGET_DIR)/etc/rc.d/rc.sysinit.d	
	
	$(BUSYBOX_FAKEROOT) ln -fs ../../init.d/mdev \
		$(BUSYBOX_TARGET_DIR)/etc/rc.d/rc.sysinit.d/S85mdev
endef
define BUSYBOX_INSTALL_MDEV_CONF
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0644 package/busybox/mdev.conf \
		$(BUSYBOX_TARGET_DIR)/etc/mdev.conf
endef
define BUSYBOX_INSTALL_MDEV_HELPERS
	$(BUSYBOX_FAKEROOT) $(INSTALL) -d -m 0755 $(BUSYBOX_TARGET_DIR)/lib/mdev/storage-device.d
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/mdev/storage-device \
		$(BUSYBOX_TARGET_DIR)/lib/mdev/storage-device
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/mdev/network-hotplug \
		$(BUSYBOX_TARGET_DIR)/lib/mdev/network-hotplug
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/mdev/storage-device.d/001-symlinks \
		$(BUSYBOX_TARGET_DIR)/lib/mdev/storage-device.d/001-symlinks
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/mdev/storage-device.d/002-automount \
		$(BUSYBOX_TARGET_DIR)/lib/mdev/storage-device.d/002-automount
endef
define BUSYBOX_SET_MDEV
	$(call KCONFIG_ENABLE_OPT,CONFIG_MDEV,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_FEATURE_MDEV_CONF,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_FEATURE_MDEV_EXEC,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_FEATURE_MDEV_LOAD_FIRMWARE,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# sha passwords need USE_BB_CRYPT_SHA
ifeq ($(BR2_TARGET_GENERIC_PASSWD_SHA256)$(BR2_TARGET_GENERIC_PASSWD_SHA512),y)
define BUSYBOX_SET_CRYPT_SHA
	$(call KCONFIG_ENABLE_OPT,CONFIG_USE_BB_CRYPT_SHA,$(BUSYBOX_BUILD_CONFIG))
endef
endif

ifeq ($(BR2_USE_MMU),y)
define BUSYBOX_SET_MMU
	$(call KCONFIG_DISABLE_OPT,CONFIG_NOMMU,$(BUSYBOX_BUILD_CONFIG))
endef
else
define BUSYBOX_SET_MMU
	$(call KCONFIG_ENABLE_OPT,CONFIG_NOMMU,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_SWAPONOFF,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_ASH,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_HUSH,$(BUSYBOX_BUILD_CONFIG))
endef
endif

ifeq ($(BR2_LARGEFILE),y)
define BUSYBOX_SET_LARGEFILE
	$(call KCONFIG_ENABLE_OPT,CONFIG_LFS,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_FDISK_SUPPORT_LARGE_DISKS,$(BUSYBOX_BUILD_CONFIG))
endef
else
define BUSYBOX_SET_LARGEFILE
	$(call KCONFIG_DISABLE_OPT,CONFIG_LFS,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_FDISK_SUPPORT_LARGE_DISKS,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# If IPv6 is enabled then enable basic ifupdown support for it
ifeq ($(BR2_INET_IPV6),y)
define BUSYBOX_SET_IPV6
	$(call KCONFIG_ENABLE_OPT,CONFIG_FEATURE_IPV6,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_FEATURE_IFUPDOWN_IPV6,$(BUSYBOX_BUILD_CONFIG))
endef
else
define BUSYBOX_SET_IPV6
	$(call KCONFIG_DISABLE_OPT,CONFIG_FEATURE_IPV6,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_FEATURE_IFUPDOWN_IPV6,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# If we're using static libs do the same for busybox
ifeq ($(BR2_STATIC_LIBS),y)
define BUSYBOX_PREFER_STATIC
	$(call KCONFIG_ENABLE_OPT,CONFIG_STATIC,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# Disable usage of inetd if netkit-base package is selected
ifeq ($(BR2_PACKAGE_NETKITBASE),y)
define BUSYBOX_NETKITBASE
	$(call KCONFIG_DISABLE_OPT,CONFIG_INETD,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# Disable usage of telnetd if netkit-telnetd package is selected
ifeq ($(BR2_PACKAGE_NETKITTELNET),y)
define BUSYBOX_NETKITTELNET
	$(call KCONFIG_DISABLE_OPT,CONFIG_TELNETD,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# Disable shadow passwords support if unsupported by the C library
ifeq ($(BR2_TOOLCHAIN_HAS_SHADOW_PASSWORDS),)
define BUSYBOX_INTERNAL_SHADOW_PASSWORDS
	$(call KCONFIG_ENABLE_OPT,CONFIG_USE_BB_PWD_GRP,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_USE_BB_SHADOW,$(BUSYBOX_BUILD_CONFIG))
endef
endif

# We also need to use internal functions when using the musl C
# library, since some of them are not yet implemented by musl.
ifeq ($(BR2_TOOLCHAIN_USES_MUSL),y)
define BUSYBOX_INTERNAL_SHADOW_PASSWORDS
	$(call KCONFIG_ENABLE_OPT,CONFIG_USE_BB_PWD_GRP,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_ENABLE_OPT,CONFIG_USE_BB_SHADOW,$(BUSYBOX_BUILD_CONFIG))
endef
endif

ifeq ($(BR2_INIT_BUSYBOX),y)
define BUSYBOX_SET_INIT
	$(call KCONFIG_ENABLE_OPT,CONFIG_INIT,$(BUSYBOX_BUILD_CONFIG))
endef
endif

ifeq ($(BR2_PACKAGE_KMOD_TOOLS),y)
define BUSYBOX_DISABLE_MOD_UTILS
	$(call KCONFIG_DISABLE_OPT,CONFIG_MODINFO,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_MODPROBE_SMALL,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_INSMOD,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_RMMOD,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_LSMOD,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_MODPROBE,$(BUSYBOX_BUILD_CONFIG))
	$(call KCONFIG_DISABLE_OPT,CONFIG_DEPMOD,$(BUSYBOX_BUILD_CONFIG))
endef
endif

define BUSYBOX_INSTALL_LOGGING_SCRIPT
	if grep -q CONFIG_SYSLOGD=y $(@D)/.config; then \
		$(INSTALL) -m 0755 -D package/busybox/S01logging \
			$(BUSYBOX_TARGET_DIR)/etc/init.d/S01logging; \
	else rm -f $(BUSYBOX_TARGET_DIR)/etc/init.d/S01logging; fi
endef

ifeq ($(BR2_PACKAGE_BUSYBOX_WATCHDOG),y)
define BUSYBOX_SET_WATCHDOG
	$(call KCONFIG_ENABLE_OPT,CONFIG_WATCHDOG,$(BUSYBOX_BUILD_CONFIG))
endef
define BUSYBOX_INSTALL_WATCHDOG_SCRIPT
	$(INSTALL) -D -m 0755 package/busybox/S15watchdog \
		$(BUSYBOX_TARGET_DIR)/etc/init.d/S15watchdog
	$(SED) s/PERIOD/$(call qstrip,$(BR2_PACKAGE_BUSYBOX_WATCHDOG_PERIOD))/ \
		$(BUSYBOX_TARGET_DIR)/etc/init.d/S15watchdog
endef
endif

ifeq ($(BR2_PACKAGE_BUSYBOX_CROND),y)
define BUSYBOX_SET_CROND
	$(call KCONFIG_ENABLE_OPT,CONFIG_CROND,$(BUSYBOX_BUILD_CONFIG))
endef
define BUSYBOX_INSTALL_CROND_SCRIPT
	$(BUSYBOX_FAKEROOT) mkdir -p $(BUSYBOX_TARGET_DIR)/etc/cron.{d,daily,hourly,monthly}

	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0644 package/busybox/crontab \
		$(BUSYBOX_TARGET_DIR)/etc/crontab

	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/crond.init \
		$(BUSYBOX_TARGET_DIR)/etc/init.d/crond
		
	$(BUSYBOX_FAKEROOT) $(INSTALL) -D -m 0755 package/busybox/crond.default \
		$(BUSYBOX_TARGET_DIR)/etc/default/crond
		
	$(BUSYBOX_FAKEROOT) $(INSTALL) -d -m 0755 $(BUSYBOX_TARGET_DIR)/etc/rc.d/rc.startup.d
	
	$(BUSYBOX_FAKEROOT) ln -fs ../../init.d/crond \
		$(BUSYBOX_TARGET_DIR)/etc/rc.d/rc.startup.d/S50crond
endef
endif

# Enable "noclobber" in install.sh, to prevent BusyBox from overwriting any
# full-blown versions of apps installed by other packages with sym/hard links.
define BUSYBOX_NOCLOBBER_INSTALL
	$(SED) 's/^noclobber="0"$$/noclobber="1"/' $(@D)/applets/install.sh
endef

define BUSYBOX_KCONFIG_FIXUP_CMDS
	$(BUSYBOX_SET_MMU)
	$(BUSYBOX_SET_LARGEFILE)
	$(BUSYBOX_SET_IPV6)
	$(BUSYBOX_PREFER_STATIC)
	$(BUSYBOX_SET_MDEV)
	$(BUSYBOX_SET_CRYPT_SHA)
	$(BUSYBOX_NETKITBASE)
	$(BUSYBOX_NETKITTELNET)
	$(BUSYBOX_INTERNAL_SHADOW_PASSWORDS)
	$(BUSYBOX_SET_INIT)
	$(BUSYBOX_SET_WATCHDOG)
	$(BUSYBOX_SET_CROND)
	$(BUSYBOX_DISABLE_MOD_UTILS)
	$(BUSYBOX_DISABLE_UDHCPC)
endef

define BUSYBOX_CONFIGURE_CMDS
	$(BUSYBOX_NOCLOBBER_INSTALL)
endef

define BUSYBOX_BUILD_CMDS
	$(BUSYBOX_MAKE_ENV) $(MAKE) $(BUSYBOX_MAKE_OPTS) -C $(@D)
endef

define BUSYBOX_INSTALL_INIT_LINK
	$(BUSYBOX_FAKEROOT) ln -s sbin/init $(BUSYBOX_TARGET_DIR)/init
endef

define BUSYBOX_FIX_SUID_PERMISSION
	$(BUSYBOX_FAKEROOT) chmod 4755 $(BUSYBOX_TARGET_DIR)/bin/busybox
endef

ifeq ($(BR2_PACKAGE_DHCP_CLIENT),y)
define BUSYBOX_DISABLE_UDHCPC
	$(call KCONFIG_DISABLE_OPT,CONFIG_UDHCPC,$(BUSYBOX_BUILD_CONFIG))
endef
else
define BUXYBIX_INSTALL_UDHCPC_SCRIPTS
	$(BUSYBOX_FAKEROOT) $(INSTALL) -m 0755 -D package/busybox/udhcpc.script \
		$(BUSYBOX_TARGET_DIR)/usr/share/udhcpc/default.script
	$(BUSYBOX_FAKEROOT) $(INSTALL) -m 0755 -d \
		$(BUSYBOX_TARGET_DIR)/usr/share/udhcpc/default.script.d
endef
endif

define BUSYBOX_INSTALL_TARGET_CMDS
	$(BUSYBOX_FAKEROOT) $(MAKE) $(BUSYBOX_MAKE_OPTS) -C $(@D) install
	$(BUXYBIX_INSTALL_UDHCPC_SCRIPTS)
	$(BUSYBOX_INSTALL_MDEV_CONF)
	$(BUSYBOX_INSTALL_MDEV_HELPERS)
	$(BUSYBOX_INSTALL_INIT_LINK)
endef

define BUSYBOX_INSTALL_INIT_SYSV
	$(BUSYBOX_INSTALL_MDEV_SCRIPT)
	$(BUSYBOX_INSTALL_LOGGING_SCRIPT)
	$(BUSYBOX_INSTALL_WATCHDOG_SCRIPT)
	$(BUSYBOX_INSTALL_CROND_SCRIPT)
endef

$(eval $(kconfig-package))
