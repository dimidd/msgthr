# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>
all::
pkg = msgthr
RUBY = ruby
lib := lib
VERSION := 0.0.0

all:: test
test_units := $(wildcard test/test_*.rb)
test: $(test_units)
$(test_units):
	$(RUBY) -w -I $(lib) $@ -v

check-warnings:
	@(for i in $$(git ls-files '*.rb'| grep -v '^setup\.rb$$'); \
	  do $(RUBY) -d -W2 -c $$i; done) | grep -v '^Syntax OK$$' || :

check: test

pkggem := pkg/$(pkg)-$(VERSION).gem

fix-perms:
	git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644

gem: $(pkggem)

install-gem: $(pkggem)
	gem install --local $(CURDIR)/$<

$(pkggem): .manifest
	VERSION=$(VERSION) gem build $(pkg).gemspec
	mkdir -p pkg
	mv $(@F) $@

pkg_extra :=

.manifest: fix-perms
	git ls-files | LC_ALL=C sort >$@+
	cmp $@+ $@ || mv $@+ $@; rm -f $@+

package: $(pkggem)

.PHONY: all test $(test_units)
.PHONY: check-warnings fix-perms
