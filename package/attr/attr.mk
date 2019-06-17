################################################################################
#
# attr
#
################################################################################

ATTR_VERSION = 2.4.48
ATTR_SITE = http://download.savannah.gnu.org/releases/attr
ATTR_LICENSE = GPL-2.0+ (programs), LGPL-2.1+ (libraries)
ATTR_LICENSE_FILES = doc/COPYING doc/COPYING.LGPL

define HOST_ATTR_FIX_NO_SYSCALL
	if test -f 'package/attr/0002-Switch-back-to-syscall.patch'; then \
	    mv package/attr/0002-Switch-back-to-syscall.patch package/attr/0002-Switch-back-to-syscall.patch.unused >/dev/null 2>&1; \
	fi
endef

HOST_ATTR_PRE_PATCH_HOOKS += HOST_ATTR_FIX_NO_SYSCALL

define HOST_ATTR_FIX_AS_LN_S
	$(SED) 's%cp -pR%ln -snf%' $(@D)/configure
endef

HOST_ATTR_PRE_CONFIGURE_HOOKS += HOST_ATTR_FIX_AS_LN_S

ATTR_INSTALL_STAGING = YES

ATTR_CONF_OPTS = --disable-nls

$(eval $(autotools-package))
$(eval $(host-autotools-package))
