DEB_SRCPKG := glibc-source
DEB_SRCPKGDIR := $(CURDIR)/debian/$(DEB_SRCPKG)/usr/src/$(DEB_SRCPKG)

binary-source: $(stamp)binary-source
$(stamp)binary-source:
	echo "I am binary-source target"
	mkdir -p $(DEB_SRCPKGDIR)/debian
	for f in $(DEB_TARBALL) $(GLIBC_OVERLAYS); do \
		cp $$f $(DEB_SRCPKGDIR); \
	done

	# copy debian/ directory
	for f in `find debian/ -maxdepth 1 -type f` debian/{po,local,rules.d,debhelper.in,sysdeps,control.in,patches,script.in,wrapper}; do \
		cp -a $$f $(DEB_SRCPKGDIR)/debian; \
	done
	touch $(stamp)binary-source

