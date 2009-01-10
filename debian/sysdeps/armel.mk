libc_add-ons = ports nptl $(add-ons)
libc-second_add-ons = $(libc_add-ons)
libc-headers_add-ons = $(libc_add-ons)

# First kernel version that supports EABI
libc_MIN_KERNEL_SUPPORTED = 2.6.14

# Some tests assume a fast machine
TIMEOUTFACTOR=3

# bootstrap needs this macro
libc-headers_extra_cflags = -D__ARM_EABI__

