################################################################################
#
# mesa3d
#
################################################################################

# When updating the version, please also update mesa3d-headers
MESA3D_VERSION = 19.0.6
MESA3D_SOURCE = mesa-$(MESA3D_VERSION).tar.xz
MESA3D_SITE = https://mesa.freedesktop.org/archive
MESA3D_LICENSE = MIT, SGI, Khronos
MESA3D_LICENSE_FILES = docs/license.html
# 0002-configure.ac-invert-order-for-wayland-scanner-check.patch
# 0003-set-LIBCLC_INCLUDEDIR.patch
MESA3D_AUTORECONF = YES

MESA3D_INSTALL_STAGING = YES

MESA3D_PROVIDES =

MESA3D_DEPENDENCIES = \
	host-bison \
	host-flex \
	expat \
	libdrm \
	zlib

# Disable assembly usage.
MESA3D_CONF_OPTS = --disable-asm

# autotools are deprecated in favour of meson, for now force autotools
MESA3D_CONF_OPTS += --enable-autotools

# Disable static, otherwise configure will fail with: "Cannot enable both static
# and shared."
ifeq ($(BR2_SHARED_STATIC_LIBS),y)
MESA3D_CONF_OPTS += --disable-static
endif

ifeq ($(BR2_PACKAGE_MESA3D_LLVM),y)
MESA3D_DEPENDENCIES += host-llvm llvm
MESA3D_CONF_OPTS += \
	--with-llvm-prefix=$(STAGING_DIR)/usr \
	--enable-llvm-shared-libs \
	--enable-llvm
else
# Avoid automatic search of llvm-config
MESA3D_CONF_OPTS += --disable-llvm
endif

# Disable opencl-icd: OpenCL lib will be named libOpenCL instead of
# libMesaOpenCL and CL headers are installed
ifeq ($(BR2_PACKAGE_MESA3D_OPENCL),y)
MESA3D_PROVIDES += libopencl
MESA3D_DEPENDENCIES += clang libclc
MESA3D_CONF_OPTS += --enable-opencl \
	--disable-opencl-icd \
	--with-clang-libdir=$(STAGING_DIR)/usr/lib
else
MESA3D_CONF_OPTS += --disable-opencl
endif

ifeq ($(BR2_PACKAGE_MESA3D_NEEDS_ELFUTILS),y)
MESA3D_DEPENDENCIES += elfutils
endif

# The Sourcery MIPS toolchain has a special (non-upstream) feature to
# have "compact exception handling", which unfortunately breaks with
# mesa3d, so we disable it here by passing -mno-compact-eh.
ifeq ($(BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_MIPS),y)
MESA3D_CONF_ENV += CFLAGS="$(TARGET_CFLAGS) -mno-compact-eh"
MESA3D_CONF_ENV += CXXFLAGS="$(TARGET_CXXFLAGS) -mno-compact-eh"
endif

ifeq ($(BR2_PACKAGE_XORG7),y)
MESA3D_DEPENDENCIES += \
	xlib_libX11 \
	xlib_libXext \
	xlib_libXdamage \
	xlib_libXfixes \
	xlib_libXrandr \
	xlib_libXxf86vm \
	xorgproto \
	libxcb
MESA3D_CONF_OPTS += --enable-glx --disable-mangling
# quote from mesa3d configure "Building xa requires at least one non swrast gallium driver."
ifeq ($(BR2_PACKAGE_MESA3D_NEEDS_XA),y)
MESA3D_CONF_OPTS += --enable-xa
else
MESA3D_CONF_OPTS += --disable-xa
endif
else
MESA3D_CONF_OPTS += \
	--disable-glx \
	--disable-xa
endif

# Drivers

#Gallium Drivers
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_ETNAVIV)  += etnaviv
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_KMSRO)    += kmsro
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_NOUVEAU)  += nouveau
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_R600)     += r600
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_RADEONSI) += radeonsi
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_SVGA)     += svga
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_SWRAST)   += swrast
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VC4)      += vc4
MESA3D_GALLIUM_DRIVERS-$(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VIRGL)    += virgl
# DRI Drivers
MESA3D_DRI_DRIVERS-$(BR2_PACKAGE_MESA3D_DRI_DRIVER_SWRAST) += swrast
MESA3D_DRI_DRIVERS-$(BR2_PACKAGE_MESA3D_DRI_DRIVER_I915)   += i915
MESA3D_DRI_DRIVERS-$(BR2_PACKAGE_MESA3D_DRI_DRIVER_I965)   += i965
MESA3D_DRI_DRIVERS-$(BR2_PACKAGE_MESA3D_DRI_DRIVER_NOUVEAU) += nouveau
MESA3D_DRI_DRIVERS-$(BR2_PACKAGE_MESA3D_DRI_DRIVER_RADEON) += radeon
# Vulkan Drivers
MESA3D_VULKAN_DRIVERS-$(BR2_PACKAGE_MESA3D_VULKAN_DRIVER_INTEL)   += intel

ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER),)
MESA3D_CONF_OPTS += \
	--without-gallium-drivers \
	--disable-gallium-extra-hud
else
MESA3D_CONF_OPTS += \
	--enable-shared-glapi \
	--with-gallium-drivers=$(subst $(space),$(comma),$(MESA3D_GALLIUM_DRIVERS-y)) \
	--enable-gallium-extra-hud
endif

ifeq ($(BR2_PACKAGE_MESA3D_DRI_DRIVER),)
MESA3D_CONF_OPTS += \
	--without-dri-drivers --disable-dri3
else
ifeq ($(BR2_PACKAGE_XLIB_LIBXSHMFENCE),y)
MESA3D_DEPENDENCIES += xlib_libxshmfence
MESA3D_CONF_OPTS += --enable-dri3
else
MESA3D_CONF_OPTS += --disable-dri3
endif
MESA3D_CONF_OPTS += \
	--enable-shared-glapi \
	--enable-driglx-direct \
	--with-dri-driverdir=/usr/lib/dri \
	--with-dri-drivers=$(subst $(space),$(comma),$(MESA3D_DRI_DRIVERS-y))
endif

ifeq ($(BR2_PACKAGE_MESA3D_VULKAN_DRIVER),)
MESA3D_CONF_OPTS += \
	--without-vulkan-drivers
else
MESA3D_DEPENDENCIES += xlib_libxshmfence
MESA3D_CONF_OPTS += \
	--enable-dri3 \
	--with-vulkan-drivers=$(subst $(space),$(comma),$(MESA3D_VULKAN_DRIVERS-y))
endif

# APIs

ifeq ($(BR2_PACKAGE_MESA3D_OSMESA),y)
MESA3D_CONF_OPTS += --enable-osmesa
else
MESA3D_CONF_OPTS += --disable-osmesa
endif

# Always enable OpenGL:
#   - it is needed for GLES (mesa3d's ./configure is a bit weird)
MESA3D_CONF_OPTS += --enable-opengl --enable-dri

# libva and mesa3d have a circular dependency
# we do not need libva support in mesa3d, therefore disable this option
MESA3D_CONF_OPTS += --disable-va

# libGL is only provided for a full xorg stack
ifeq ($(BR2_PACKAGE_XORG7),y)
MESA3D_PROVIDES += libgl
else
define MESA3D_REMOVE_OPENGL_HEADERS
	rm -rf $(STAGING_DIR)/usr/include/GL/
endef

MESA3D_POST_INSTALL_STAGING_HOOKS += MESA3D_REMOVE_OPENGL_HEADERS
endif

ifeq ($(BR2_PACKAGE_MESA3D_DRI_DRIVER),y)
MESA3D_PLATFORMS = drm
else ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VC4),y)
MESA3D_PLATFORMS = drm
else ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_ETNAVIV),y)
MESA3D_PLATFORMS = drm
else ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_VIRGL),y)
MESA3D_PLATFORMS = drm
else ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_RADEONSI),y)
MESA3D_PLATFORMS = drm
endif
ifeq ($(BR2_PACKAGE_WAYLAND),y)
MESA3D_DEPENDENCIES += wayland wayland-protocols
MESA3D_PLATFORMS += wayland
endif
ifeq ($(BR2_PACKAGE_XORG7),y)
MESA3D_PLATFORMS += x11
endif

MESA3D_CONF_OPTS += \
	--with-platforms=$(subst $(space),$(comma),$(MESA3D_PLATFORMS))

ifeq ($(BR2_PACKAGE_MESA3D_OPENGL_EGL),y)
MESA3D_PROVIDES += libegl
MESA3D_CONF_OPTS += \
	--enable-gbm \
	--enable-egl
else
MESA3D_CONF_OPTS += \
	--disable-egl
endif

ifeq ($(BR2_PACKAGE_MESA3D_OPENGL_ES),y)
MESA3D_PROVIDES += libgles
MESA3D_CONF_OPTS += --enable-gles1 --enable-gles2
else
MESA3D_CONF_OPTS += --disable-gles1 --disable-gles2
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBXVMC),y)
MESA3D_DEPENDENCIES += xlib_libXvMC
MESA3D_CONF_OPTS += --enable-xvmc
else
MESA3D_CONF_OPTS += --disable-xvmc
endif

ifeq ($(BR2_PACKAGE_LIBUNWIND),y)
MESA3D_CONF_OPTS += --enable-libunwind
MESA3D_DEPENDENCIES += libunwind
else
MESA3D_CONF_OPTS += --disable-libunwind
endif

ifeq ($(BR2_PACKAGE_LIBVDPAU),y)
MESA3D_DEPENDENCIES += libvdpau
MESA3D_CONF_OPTS += --enable-vdpau
else
MESA3D_CONF_OPTS += --disable-vdpau
endif

ifeq ($(BR2_PACKAGE_LM_SENSORS),y)
MESA3D_CONF_OPTS += --enable-lmsensors
MESA3D_DEPENDENCIES += lm-sensors
else
MESA3D_CONF_OPTS += --disable-lmsensors
endif

$(eval $(autotools-package))
