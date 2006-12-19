libc_add-ons = linuxthreads ports $(add-ons)
libc_extra_config_options = $(extra_config_options) --disable-sanity-checks --without-tls --without-__thread
#libc-headers_add-ons = linuxthreads $(add-ons)
#with_fp := --without-fp

