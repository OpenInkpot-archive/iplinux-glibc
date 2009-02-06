libc_add-ons = ports nptl $(add-ons)
libc-second_add-ons = $(libc_add-ons)
libc-headers_add-ons = $(libc_add-ons)

libc_configure-args = libc_cv_arm_tls=yes
libc-second_configure-args = $(libc_configure-args)
libc-headers_configure-args = $(libc_configure-args)

# First kernel version that supports EABI
libc_MIN_KERNEL_SUPPORTED = 2.6.14

# Some tests assume a fast machine
TIMEOUTFACTOR=3

# bootstrap needs this macro. It is expected to be defined by the compiler on
# later stages.

libc-headers_extra_cflags = -D__ARM_EABI__
