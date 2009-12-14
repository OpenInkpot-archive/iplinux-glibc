# This is so horribly wrong.  libc-pic does a whole pile of gratuitous
# renames.  There's very little we can do for now.  Maybe after
# Sarge releases we can consider breaking packages, but certainly not now.

$(stamp)binaryinst_$(libc)-pic:: $(stamp)debhelper
	@echo Running special kludge for $(libc)-pic
	dh_testroot
	dh_installdirs -p$(curpass)
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/libc_pic.a debian/$(libc)-pic/usr/lib/.
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/libc.map debian/$(libc)-pic/usr/lib/libc_pic.map
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/elf/soinit.os debian/$(libc)-pic/usr/lib/libc_pic/soinit.o
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/elf/sofini.os debian/$(libc)-pic/usr/lib/libc_pic/sofini.o

	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/math/libm_pic.a debian/$(libc)-pic/usr/lib/.
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/libm.map debian/$(libc)-pic/usr/lib/libm_pic.map
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/resolv/libresolv_pic.a debian/$(libc)-pic/usr/lib/.
	install --mode=0644 build-tree/$(DEB_HOST_ARCH)-libc/libresolv.map debian/$(libc)-pic/usr/lib/libresolv_pic.map

# Some per-package extra files to install.
define $(libc)_extra_debhelper_pkg_install
endef

# Should each of these have per-package options?

$(patsubst %,binaryinst_%,$(DEB_ARCH_REGULAR_PACKAGES) $(DEB_INDEP_REGULAR_PACKAGES)) :: binaryinst_% : $(stamp)binaryinst_%

# Make sure the debug packages are built last, since other packages may add
# files to them.
debug-packages = $(filter %-dbg,$(DEB_ARCH_REGULAR_PACKAGES))
non-debug-packages = $(filter-out %-dbg,$(DEB_ARCH_REGULAR_PACKAGES))
$(patsubst %,$(stamp)binaryinst_%,$(debug-packages)):: $(patsubst %,$(stamp)binaryinst_%,$(non-debug-packages))

$(patsubst %,$(stamp)binaryinst_%,$(DEB_ARCH_REGULAR_PACKAGES) $(DEB_INDEP_REGULAR_PACKAGES)):: $(stamp)debhelper
	@echo Running debhelper for $(curpass)
	dh_testroot
	dh_installdirs -p$(curpass)
	dh_install -p$(curpass)
	dh_installdebconf -p$(curpass)
	dh_installinit -p$(curpass)
	dh_link -p$(curpass)
	set -e; if test -d debian/bug/$(curpass); then                   \
	    dh_installdirs -p$(curpass) usr/share/bug;                   \
	    dh_install -p$(curpass) debian/bug/$(curpass) usr/share/bug; \
	fi

	# extra_debhelper_pkg_install is used for debhelper.mk only.
	# when you want to install extra packages, use extra_pkg_install.
	$(call xx,extra_debhelper_pkg_install)
	$(call xx,extra_pkg_install)

ifeq ($(filter nostrip,$(DEB_BUILD_OPTIONS)),)
	# libpthread must be stripped specially; GDB needs the
	# non-dynamic symbol table in order to load the thread
	# debugging library.  We keep a full copy of the symbol
	# table in libc6-dbg but basic thread debugging should
	# work even without that package installed.

	# We use a wrapper script so that we only include the bare
	# minimum in /usr/lib/debug/lib for backtraces; anything
	# else takes too long to load in GDB.

	if test "$(NOSTRIP_$(curpass))" != 1; then			\
	  chmod a+x debian/wrapper/objcopy;				\
	  export PATH=$(shell pwd)/debian/wrapper:$$PATH;		\
	  dh_strip -p$(curpass) -Xlibpthread --dbg-package=$(libc)-dbg; \
	  (cd debian/$(curpass);					\
	   find . -name libpthread-\*.so -exec				\
	     ../../debian/wrapper/objcopy --only-keep-debug '{}'	\
	     ../$(libc)-dbg/usr/lib/debug/'{}' ';' || true;		\
	   find . -name libpthread-\*.so -exec objcopy			\
	     --add-gnu-debuglink=../$(libc)-dbg/usr/lib/debug/'{}'	\
	     '{}' ';' || true);						\
	  find debian/$(curpass) -name libpthread-\*.so -exec		\
	    strip --strip-debug --remove-section=.comment		\
	    --remove-section=.note '{}' ';' || true;			\
	fi
endif

	dh_compress -p$(curpass)
	dh_fixperms -p$(curpass) -Xpt_chown
	# Use this instead of -X to dh_fixperms so that we can use
	# an unescaped regular expression.  ld.so must be executable;
	# libc.so and NPTL's libpthread.so print useful version
	# information when executed.
	find debian/$(curpass) -type f \( -regex '.*/ld.*so' \
		-o -regex '.*/libpthread-.*so' \
		-o -regex '.*/libc-.*so' \) \
		-exec chmod a+x '{}' ';'
	dh_makeshlibs -X/usr/lib/debug -p$(curpass) -V "$(call xx,shlib_dep)"

	dh_installdeb -p$(curpass)
	if [ $(curpass) = nscd ] ; then \
		dh_shlibdeps -p$(curpass) ; \
	fi
	dh_gencontrol -p$(curpass) -- $($(curpass)_control_flags)
	if [ $(curpass) = nscd ] ; then \
		sed -i -e "s/\(Depends:.*libc[0-9.]\+\)-[a-z0-9]\+/\1/" debian/nscd/DEBIAN/control ; \
	fi
	dh_md5sums -p$(curpass)
	dh_builddeb -p$(curpass)

	touch $@

$(patsubst %,binaryinst_%,$(DEB_UDEB_PACKAGES)) :: binaryinst_% : $(stamp)binaryinst_%
$(patsubst %,$(stamp)binaryinst_%,$(DEB_UDEB_PACKAGES)): $(stamp)debhelper
	@echo Running debhelper for $(curpass)
	dh_testroot
	dh_installdirs -p$(curpass)
	dh_install -p$(curpass)
	dh_strip -p$(curpass)

	# when you want to install extra packages, use extra_pkg_install.
	$(call xx,extra_pkg_install)

	dh_compress -p$(curpass)
	dh_fixperms -p$(curpass)
	find debian/$(curpass) -type f \( -regex '.*lib[0-9]*/ld.*so.*' \
		-o -regex '.*lib[0-9]*/.*libpthread.*so.*' \
		-o -regex '.*lib[0-9]*/libc[.-].*so.*' \) \
		-exec chmod a+x '{}' ';'
	dh_installdeb -p$(curpass)
	# dh_shlibdeps -p$(curpass)
	dh_gencontrol -p$(curpass)
	dh_builddeb -p$(curpass)

	touch $@

OPT_PASSES = $(filter-out libc libc-second, $(GLIBC_PASSES))
OPT_DIRS = $(foreach pass,$(OPT_PASSES),$($(pass)_slibdir) $($(pass)_libdir))

debhelper: $(stamp)debhelper
$(stamp)debhelper:

	for x in `find debian/debhelper.in -maxdepth 1 -type f`; do \
	  y=debian/`basename $$x`; \
	  z=`echo $$y | sed -e 's#/libc#/$(libc)#'`; \
	  cp $$x $$z; \
	  sed -e "s#DEB_SRCDIR#$(DEB_SRCDIR)#" -i $$z; \
	  sed -e "/KERNEL_VERSION_CHECK/r debian/script.in/kernelcheck.sh" -i $$z; \
	  sed -e "/NSS_CHECK/r debian/script.in/nsscheck.sh" -i $$z; \
	  sed -e "/NOHWCAP/r debian/script.in/nohwcap.sh" -i $$z; \
	  sed -e "s#LIBC#$(libc)#" -i $$z; \
	  sed -e "s#CURRENT_VER#$(DEB_VERSION)#" -i $$z; \
	  sed -e "s#EXIT_CHECK##" -i $$z; \
	  sed -e "s#DEB_HOST_ARCH#$(DEB_HOST_ARCH)#" -i $$z; \
	  case $$z in \
	    *.install) \
	      sed -e "s/^#.*//" -i $$z ; \
	      sed -i "/^.*librpcsvc.a.*/d" $$z ; \
	      ;; \
	    debian/$(libc).preinst) \
	      rtld=`LANG=C LC_ALL=C readelf -l debian/tmp-libc/usr/bin/iconv | grep "interpreter" | sed -e 's/.*interpreter: \(.*\)]/\1/g'`; \
	      c_so=`ls debian/tmp-libc/lib/ | grep "libc\.so\."` ; \
	      m_so=`ls debian/tmp-libc/lib/ | grep "libm\.so\."` ; \
	      pthread_so=`ls debian/tmp-libc/lib/ | grep "libpthread\.so\."` ; \
	      rt_so=`ls debian/tmp-libc/lib/ | grep "librt\.so\."` ; \
	      dl_so=`ls debian/tmp-libc/lib/ | grep "libdl\.so\."` ; \
	      sed -e "s#RTLD#$$rtld#" -e "s#C_SO#$$c_so#" -e "s#M_SO#$$m_so#" -e "s#PTHREAD_SO#$$pthread_so#" -e "s#RT_SO#$$rt_so#" -e "s#DL_SO#$$dl_so#" -i $$z ; \
	      ;; \
	  esac; \
	done

	# Second stage of bootstrap forces us to generate stripped down
	# libc6/libc6-dev, so let's remove all the not-yet-built stuff here.
	if [ "$(GLIBC_PASSES)" = "libc-second" ]; then \
		sed -e 's/tmp-libc/tmp-libc-second/g' -e '/usr\/bin/d' -i debian/$(libc)-dev.install; \
		sed -e 's/tmp-libc/tmp-libc-second/g' -e '1q' -i debian/$(libc).install; \
	fi

	# Substitute __PROVIDED_LOCALES__.
	perl -i -pe 'BEGIN {undef $$/; open(IN, "debian/tmp-libc/usr/share/i18n/SUPPORTED"); $$j=<IN>;} s/__PROVIDED_LOCALES__/$$j/g;' debian/locales.config debian/locales.postinst

	# Generate common substvars files.

	# for pkg in $(DEB_ARCH_REGULAR_PACKAGES) $(DEB_INDEP_REGULAR_PACKAGES) $(DEB_UDEB_PACKAGES); do \
	#   cp tmp.substvars debian/$$pkg.substvars; \
	# done
	# rm -f tmp.substvars

	touch $(stamp)debhelper

debhelper-clean:
	dh_clean 

	rm -f debian/*.install*
	rm -f debian/*.install.*
	rm -f debian/*.manpages
	rm -f debian/*.links
	rm -f debian/*.postinst
	rm -f debian/*.preinst
	rm -f debian/*.postinst
	rm -f debian/*.prerm
	rm -f debian/*.postrm
	rm -f debian/*.info
	rm -f debian/*.init
	rm -f debian/*.config
	rm -f debian/*.templates
	rm -f debian/*.dirs
	rm -f debian/*.docs
	rm -f debian/*.doc-base
	rm -f debian/*.generated
	rm -f debian/*.lintian
	rm -f debian/*.linda
	rm -f debian/*.NEWS
	rm -f debian/*.README.Debian

	rm -f $(stamp)binaryinst*
