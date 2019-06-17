################################################################################
#
# acl
#
################################################################################

ACL_VERSION = 2.2.53
ACL_SITE = http://download.savannah.gnu.org/releases/acl
ACL_LICENSE = GPL-2.0+ (programs), LGPL-2.1+ (libraries)
ACL_LICENSE_FILES = doc/COPYING doc/COPYING.LGPL

define HOST_ACL_FIX_AS_LN_S
	$(SED) 's%cp -pR%ln -snf%' $(@D)/configure
	$(SED) 's%	$$as_ln_s%\#	$$as_ln_s%' $(@D)/configure
endef

HOST_ACL_PRE_CONFIGURE_HOOKS += HOST_ACL_FIX_AS_LN_S

define HOST_ACL_FIX_INCLUDE_ACL_SYS
	mkdir -p $(@D)/include/acl
	mkdir -p $(@D)/include/sys
	cp -rf $(@D)/include/acl.h $(@D)/include/acl/acl.h
	cp -rf $(@D)/include/acl.h $(@D)/include/sys/acl.h
endef

define HOST_ACL_FIX_TOOLS_CHACL_C
	$(SED) 's%dirent64%dirent%'   $(@D)/tools/chacl.c
	$(SED) 's%readdir64%readdir%' $(@D)/tools/chacl.c
endef

HOST_ACL_POST_CONFIGURE_HOOKS += HOST_ACL_FIX_INCLUDE_ACL_SYS HOST_ACL_FIX_TOOLS_CHACL_C

ACL_DEPENDENCIES = attr
HOST_ACL_DEPENDENCIES = host-attr

ACL_INSTALL_STAGING = YES

ACL_CONF_OPTS = --disable-nls

$(eval $(autotools-package))
$(eval $(host-autotools-package))
