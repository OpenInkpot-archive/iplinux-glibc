# Because variables can be masked at anypoint by declaring
# PASS_VAR, we need to call all variables as $(call xx,VAR)
# This little bit of magic makes it possible:
xx=$(if $($(curpass)_$(1)),$($(curpass)_$(1)),$($(1)))

# We want to log output to a logfile but we also need to preserve the
# return code of the command being run.
# This little bit of magic makes it possible:
# $(call logme, [-a] <log file>, <cmd>)
define logme
(exec 3>&1; exit `( ( ( $(2) ) 2>&1 3>&-; echo $$? >&4) | tee $(1) >&3) 4>&1`)
endef

ifeq ($(GLIBC_PASSES),libc-second)
	install_target := install-lib-all
else
	install_target := install
endif

$(patsubst %,mkbuilddir_%,$(GLIBC_PASSES)) :: mkbuilddir_% : $(stamp)mkbuilddir_%
$(stamp)mkbuilddir_%: $(stamp)patch-stamp $(KERNEL_HEADER_DIR)
	@echo Making builddir for $(curpass)
	test -d $(DEB_BUILDDIR) || mkdir $(DEB_BUILDDIR)
	touch $@

$(patsubst %,configure_%,$(GLIBC_PASSES)) :: configure_% : $(stamp)configure_%
$(stamp)configure_%: $(stamp)mkbuilddir_%

	@echo Configuring $(curpass)
	rm -f $(DEB_BUILDDIR)/configparms
	echo "CC = $(call xx,CC)"		>> $(DEB_BUILDDIR)/configparms
	echo "CXX = $(call xx,CXX)"		>> $(DEB_BUILDDIR)/configparms
	echo "BUILD_CC = $(BUILD_CC)"		>> $(DEB_BUILDDIR)/configparms
	echo "BUILD_CXX = $(BUILD_CXX)"		>> $(DEB_BUILDDIR)/configparms
	echo "CFLAGS = $(HOST_CFLAGS)"		>> $(DEB_BUILDDIR)/configparms
	echo "BUILD_CFLAGS = $(BUILD_CFLAGS)" 	>> $(DEB_BUILDDIR)/configparms
	echo "LDFLAGS = "		 	>> $(DEB_BUILDDIR)/configparms
	echo "BASH := /bin/bash"		>> $(DEB_BUILDDIR)/configparms
	echo "KSH := /bin/bash"			>> $(DEB_BUILDDIR)/configparms
	echo "LIBGD = no"			>> $(DEB_BUILDDIR)/configparms
	echo "bindir = $(bindir)"		>> $(DEB_BUILDDIR)/configparms
	echo "datadir = $(datadir)"		>> $(DEB_BUILDDIR)/configparms
	echo "localedir = $(localedir)" 	>> $(DEB_BUILDDIR)/configparms
	echo "sysconfdir = $(sysconfdir)" 	>> $(DEB_BUILDDIR)/configparms
	echo "libexecdir = $(libexecdir)" 	>> $(DEB_BUILDDIR)/configparms
	echo "rootsbindir = $(rootsbindir)" 	>> $(DEB_BUILDDIR)/configparms
	echo "includedir = $(call xx,includedir)" >> $(DEB_BUILDDIR)/configparms
	echo "docdir = $(docdir)"		>> $(DEB_BUILDDIR)/configparms
	echo "mandir = $(mandir)"		>> $(DEB_BUILDDIR)/configparms
	echo "sbindir = $(sbindir)"		>> $(DEB_BUILDDIR)/configparms
	libdir="$(call xx,libdir)" ; if test -n "$$libdir" ; then \
		echo "libdir = $$libdir" >> $(DEB_BUILDDIR)/configparms ; \
	fi
	slibdir="$(call xx,slibdir)" ; if test -n "$$slibdir" ; then \
		echo "slibdir = $$slibdir" >> $(DEB_BUILDDIR)/configparms ; \
	fi
	rtlddir="$(call xx,rtlddir)" ; if test -n "$$rtlddir" ; then \
		echo "rtlddir = $$rtlddir" >> $(DEB_BUILDDIR)/configparms ; \
	fi

	# Prevent autoconf from running unexpectedly by setting it to false.
	# Also explicitly pass CC down - this is needed to get -m64 on
	# Sparc, et cetera.

	configure_build=$(call xx,configure_build); \
	if [ $(call xx,configure_target) = $$configure_build ]; then \
	  echo "Checking that we're running at least kernel version: $(call xx,MIN_KERNEL_SUPPORTED)"; \
	  if ! $(call kernel_check,$(call xx,MIN_KERNEL_SUPPORTED)); then \
	    configure_build=`echo $$configure_build | sed 's/^\([^-]*\)-\([^-]*\)$$/\1-dummy-\2/'`; \
	    echo "No.  Forcing cross-compile by setting build to $$configure_build."; \
	  fi; \
	fi; \
	$(call logme, -a $(log_build), echo -n "Build started: " ; date --rfc-2822 ; echo "---------------") ; \
	$(call logme, -a $(log_build), \
		cd $(DEB_BUILDDIR) && \
		CC="$(call xx,CC)" \
		CXX="$(call xx,CXX)" \
		AUTOCONF=false \
		MAKEINFO=: \
		$(call xx,configure-args) \
		ac_cv_objext=o \
		libc_cv_forced_unwind=yes \
		libc_cv_c_cleanup=yes \
		$(CURDIR)/$(DEB_SRCDIR)/configure \
		--host=$(call xx,configure_target) \
		--build=$$configure_build --prefix=/usr --without-cvs \
		--enable-add-ons=$(standard-add-ons)"$(call xx,add-ons)" \
		--enable-profile \
		--without-selinux \
		$(call xx,with_headers) $(call xx,extra_config_options))
	touch $@

	if [ $(curpass) = libc ]; then \
	  $(call logme, -a $(log_build), \
	    mkdir -p $(DEB_BUILDDIR)/localedef-eglibc && \
		cd $(DEB_BUILDDIR)/localedef-eglibc && \
	    CPPFLAGS= $(CURDIR)/$(DEB_SRCDIR)/localedef-eglibc-2.9/configure \
	       --with-glibc=$(CURDIR)/$(DEB_SRCDIR)/localedef-eglibc-2.9/eglibc-2.9) \
	fi

$(patsubst %,build_%,$(GLIBC_PASSES)) :: build_% : $(stamp)build_%
$(stamp)build_%: $(stamp)configure_%
	@echo Building $(curpass)
	if [ $(curpass) = libc ] || [ $(curpass) = libc-second ]; then \
	  $(call logme, -a $(log_build), $(MAKE) -C $(DEB_BUILDDIR) $(NJOBS)); \
	  $(call logme, -a $(log_build), echo "---------------" ; echo -n "Build ended: " ; date --rfc-2822); \
	fi
	if [ $(curpass) = libc ]; then \
	  $(call logme, -a $(log_build), $(MAKE) -C $(DEB_BUILDDIR)/localedef-eglibc $(NJOBS)); \
	  $(call logme, -a $(log_build), \
	    mkdir -p $(CURDIR)/$(DEB_BUILDDIR)/localedef-eglibc/locales; \
	    for i in $(shell cat $(CURDIR)/debian/locales-list); do \
	      I18NPATH=$(CURDIR)/$(DEB_SRCDIR)/localedata $(DEB_BUILDDIR)/localedef-eglibc/localedef \
	          -i \$$i -f UTF-8 $(CURDIR)/$(DEB_BUILDDIR)/localedef-eglibc/locales/\$$i.UTF-8; \
		done); \
	fi
#if [ $(curpass) = libc ]; then \
#  $(MAKE) -C $(DEB_BUILDDIR) $(NJOBS) \
#    objdir=$(DEB_BUILDDIR) install_root=$(CURDIR)/build-tree/locales-all \
#      localedata/install-locales; \
#    tar --use-compress-program /usr/bin/lzma --owner root --group root -cf $(CURDIR)/build-tree/locales-all/supported.tar.lzma -C $(CURDIR)/build-tree/locales-all/usr/lib/locale .; \
#fi
	touch $@

$(patsubst %,install_%,$(GLIBC_PASSES)) :: install_% : $(stamp)install_%
$(stamp)install_%: $(stamp)build_%
	@echo Installing $(curpass)
	rm -rf $(CURDIR)/debian/tmp-$(curpass)
	mkdir -p $(DEB_BUILDDIR)/elf
	if [ $(curpass) = libc-headers ]; then \
		CC="$(call xx,CC)" \
		$(MAKE) -C $(DEB_BUILDDIR) $(NJOBS) \
		  CC="$(call xx,CC)" \
		  $(DEB_BUILDDIR)/sysdeps/gnu/errlist.c 2>&1; \
		mkdir -p $(DEB_BUILDDIR)/stdio-common; \
		touch $(DEB_BUILDDIR)/stdio-common/errlist-compat.c; \
		mkdir $(DEB_BUILDDIR)/rpcsvc; \
		touch $(DEB_BUILDDIR)/rpcsvc/bootparam.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/bootparam_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/key_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/klm_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/mount.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nfs_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nis_callback.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nis.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nislib.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nis_tags.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/nlm_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/rex.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/rquota.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/rstat.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/rusers.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/sm_inter.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/spray.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/ypclnt.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/yp.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/yppasswd.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/yp_prot.h; \
		touch $(DEB_BUILDDIR)/rpcsvc/ypupd.h; \
	else \
       $(MAKE) -C $(DEB_BUILDDIR) \
         install_root=$(CURDIR)/debian/tmp-$(curpass) $(install_target); \
	fi

# Install headers no matter what
	$(MAKE) -C $(DEB_BUILDDIR) $(NJOBS) \
	  CC="$(call xx,CC)" \
	  install_root=$(CURDIR)/debian/tmp-$(curpass) prefix=/usr install-headers; \
	  cp $(DEB_SRCDIR)/include/gnu/stubs.h $(CURDIR)/debian/tmp-$(curpass)/usr/include/gnu; \
	  cp $(DEB_BUILDDIR)/bits/stdio_lim.h $(CURDIR)/debian/tmp-$(curpass)/usr/include/bits; \
	  cp $(DEB_BUILDDIR)/misc/syscall-list.h $(CURDIR)/debian/tmp-$(curpass)/usr/include/bits/syscall.h

	if [ $(curpass) = libc ]; then \
	  mkdir -p $(CURDIR)/debian/tmp-$(curpass)/usr/lib/locale-archive; \
	  (cd $(DEB_BUILDDIR)/localedef-eglibc/locales \
	   && tar --lzma --hard-dereference \
	          -cf $(CURDIR)/debian/tmp-$(curpass)/usr/lib/locale-archive/main.tar.lzma * && \
	   for i in $(shell cat $(CURDIR)/debian/locales-list); do \
	     ln -s main.tar.lzma $(CURDIR)/debian/tmp-$(curpass)/usr/lib/locale-archive/$$i; \
	   done); \
	fi

# Create the multidir directories, and the configuration file in /etc/ld.so.conf.d
#if [ $(curpass) = libc ]; then \
#  mkdir -p debian/tmp-$(curpass)/etc/ld.so.conf.d; \
#  machine=`sed '/^ *config-machine *=/!d;s/.*= *//g' $(DEB_BUILDDIR)/config.make`; \
#  os=`sed '/^ *config-os *=/!d;s/.*= *//g' $(DEB_BUILDDIR)/config.make`; \
#  triplet="$$machine-$$os"; \
#  mkdir -p debian/tmp-$(curpass)/lib/$$triplet debian/tmp-$(curpass)/usr/lib/$$triplet; \
#  conffile="debian/tmp-$(curpass)/etc/ld.so.conf.d/$$triplet.conf"; \
#  echo "# Multiarch support" > $$conffile; \
#  echo /lib/$$triplet >> $$conffile; \
#  echo /usr/lib/$$triplet >> $$conffile; \
#fi

# Create a default configuration file that adds /usr/local/lib to the search path
	if [ $(curpass) = libc ]; then \
	  mkdir -p debian/tmp-$(curpass)/etc/ld.so.conf.d; \
	  echo "# libc default configuration" > debian/tmp-$(curpass)/etc/ld.so.conf.d/libc.conf ; \
	  echo /usr/local/lib >> debian/tmp-$(curpass)/etc/ld.so.conf.d/libc.conf ; \
	fi

	$(call xx,extra_install)
	touch $@

.NOTPARALLEL: $(patsubst %,install_%,$(GLIBC_PASSES))
