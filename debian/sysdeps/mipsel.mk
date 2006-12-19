libc_add-ons = ports linuxthreads $(add-ons)
libc-headers_add-ons = ports linuxthreads $(add-ons)

libc_extra_config_options = $(extra_config_options) --without-__thread --disable-sanity-checks --without-tls
