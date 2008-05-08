libc_add-ons = nptl ports $(add-ons)
libc_MIN_KERNEL_SUPPORTED=2.6.14
libc_extra_config_options = $(extra_config_options) --disable-sanity-checks
libc-headers_add-ons = nptl ports $(add-ons)
