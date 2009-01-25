libc_add-ons = nptl $(add-ons)
libc-second_add-ons = $(libc_add-ons)
libc-headers_add-ons = $(libc_add-ons)

libc_configure-args = libc_cv_slibdir=/lib

libc_slibdir = /lib
libc_libdir = /usr/lib
libc_rtlddir = /lib

# Force slibdir to be /lib: configure tries to be smart and changes slibdir to /lib64
libc_configure-args = libc_cv_slibdir=/lib

libc-headers_slibdir = $(libc_slibdir)
libc-headers_libdir = $(libc_libdir)
libc-headers_rtlddir = $(libc_rtlddir)
libc-headers_configure-args = $(libc_configure-args)

libc-second_slibdir = $(libc_slibdir)
libc-second_libdir = $(libc_libdir)
libc-second_rtlddir = $(libc_rtlddir)
libc-second_configure-args = $(libc_configure-args)

# /lib64 and /usr/lib64 are provided by glibc instead base-files: #259302.
#define libc6_extra_pkg_install
#ln -sf /lib debian/$(curpass)/lib64
#ln -sf lib debian/$(curpass)/usr/lib64
#endef

# build 32-bit (i386) alternative library
libc6-i386_shlib_dep = libc6-i386 (>= $(shlib_dep_ver))
i386_add-ons = nptl $(add-ons)
i386_configure_target = i486-linux
i386_CC = $(CC) -m32
i386_extra_cflags = -march=pentium4 -O3
i386_extra_config_options = $(extra_config_options)
i386_includedir = /usr/include/i486-linux-gnu
i386_rtlddir = /lib
i386_slibdir = /emul/ia32-linux/lib
i386_libdir = /emul/ia32-linux/usr/lib

define libc6-dev-i386_extra_pkg_install
mkdir -p debian/libc6-dev-i386/usr/include/gnu
cp -af debian/tmp-i386/usr/include/i486-linux-gnu/gnu/stubs-32.h \
	debian/libc6-dev-i386/usr/include/gnu
mkdir -p debian/libc6-dev-i386/usr/include/sys
cp -af debian/tmp-i386/usr/include/i486-linux-gnu/sys/elf.h \
	debian/libc6-dev-i386/usr/include/sys
cp -af debian/tmp-i386/usr/include/i486-linux-gnu/sys/vm86.h \
	debian/libc6-dev-i386/usr/include/sys
mkdir -p debian/libc6-dev-i386/usr/include/i486-linux-gnu
endef

define libc6-i386_extra_pkg_install
mkdir -p debian/libc6-i386/lib
ln -sf /emul/ia32-linux/lib/ld-linux.so.2 debian/libc6-i386/lib
ln -sf /emul/ia32-linux/lib debian/libc6-i386/lib32
ln -sf /emul/ia32-linux/usr/lib debian/libc6-i386/usr/lib32
endef

