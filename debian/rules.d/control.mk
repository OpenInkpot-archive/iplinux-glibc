control_deps := $(addprefix debian/control.in/, libc6 libc6.1 libc0.1 libc0.3 mipsn32 mips64)

debian/control.in/libc6: debian/control.in/libc debian/rules.d/control.mk
	sed -e 's%@libc@%libc6%g' \
	    -e 's%@archs@%amd64 arm armeb armel i386 m32r m68k mips mipsel powerpc ppc64 sparc s390 hppa sh3 sh4 sh3eb sh4eb%g' < $< > $@

debian/control.in/libc6.1: debian/control.in/libc debian/rules.d/control.mk
	sed -e 's%@libc@%libc6.1%g;s%@archs@%alpha ia64%g' < $< > $@

debian/control.in/libc0.3: debian/control.in/libc debian/rules.d/control.mk
	sed -e 's%@libc@%libc0.3%g;s%@archs@%hurd-i386%g;s/nscd, //' < $< > $@

debian/control.in/libc0.1: debian/control.in/libc debian/rules.d/control.mk
	sed -e 's%@libc@%libc0.1%g;s%@archs@%kfreebsd-i386 kfreebsd-amd64%g' < $< > $@

debian/control: $(stamp)control
$(stamp)control: debian/control.in/main $(control_deps) \
		   debian/rules.d/control.mk # debian/sysdeps/depflags.pl

	# Check that all files end with a new line
	set -e ; for i in debian/control.in/* ; do \
		tail -n1 $$i | grep -q "^$$" ; \
	done

	cat debian/control.in/main		>  $@T
	cat debian/control.in/libc6		>> $@T
	cat debian/control.in/libc6.1		>> $@T
	cat debian/control.in/libc0.3		>> $@T
	cat debian/control.in/libc0.1		>> $@T
	cat debian/control.in/mipsn32		>> $@T
	cat debian/control.in/mips64		>> $@T
	sed -e 's%@libc@%$(libc)%g;s%@glibc@%glibc%g' < $@T > debian/control
	rm $@T
	touch $@
