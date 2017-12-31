# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>
all::
pkg = msgthr
RUBY = ruby
lib := lib
VERSION := 1.1.0
RSYNC_DEST := 80x24.org:/srv/80x24/msgthr/

RSYNC = rsync
OLDDOC = olddoc
RDOC = rdoc

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

NEWS: .olddoc.yml
	$(OLDDOC) prepare
LATEST: NEWS

doc:: .document .olddoc.yml
	-find lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	$(RDOC) -f oldweb

# this requires GNU coreutils variants
ifneq ($(RSYNC_DEST),)
publish_doc:
	-git set-file-times
	$(MAKE) doc
	mkdir -p www
	$(RM) -r www/rdoc
	mv doc www/rdoc
	install -m644 README www/README
	install -m644 NEWS www/NEWS
	install -m644 NEWS.atom.xml www/NEWS.atom.xml
	for i in $$(find www -type f ! -regex '^.*\.gz$$'); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done
	$(RSYNC) -av www/ $(RSYNC_DEST)
	git ls-files | xargs touch
endif

.PHONY: all test $(test_units)
.PHONY: check-warnings fix-perms
