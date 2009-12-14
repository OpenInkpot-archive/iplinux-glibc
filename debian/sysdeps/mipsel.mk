libc_add-ons = ports nptl $(add-ons)
libc-second_add-ons = $(libc_add-ons)
libc-headers_add-ons = $(libc_add-ons)

libc_configure-args = libc_cv_mips_tls=yes
libc-second_configure-args = $(libc_configure-args)
libc-headers_configure-args = $(libc_configure-args)

# glibc can't detect softfp from the GCC configuration. Oh well...
# See the http://sourceware.org/ml/libc-ports/2007-06/msg00008.html
extra_config_options = --without-fp

# Some tests assume a fast machine
TIMEOUTFACTOR=2

# bootstrap needs these macros. They are expected to be defined by the compiler
# on later stages.

libc-headers_extra_cflags = -D_MIPS_SZPTR=32 -D__MIPSEL__
