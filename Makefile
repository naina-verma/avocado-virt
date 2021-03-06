PYTHON=$(shell which python)
DESTDIR=/
BUILDIR=$(CURDIR)/debian/avocado-virt
PROJECT=avocado
VERSION="0.34.0"
AVOCADO_DIRNAME?=avocado
DIRNAME=$(shell echo $${PWD\#\#*/})

RELEASE_COMMIT=$(shell git log --pretty=format:'%H' -n 1 $(VERSION))
RELEASE_SHORT_COMMIT=$(shell git log --pretty=format:'%h' -n 1 $(VERSION))

COMMIT=$(shell git log --pretty=format:'%H' -n 1)
SHORT_COMMIT=$(shell git log --pretty=format:'%h' -n 1)

all:
	@echo
	@echo "Development related targets:"
	@echo "check:  Runs tree static check, unittests and functional tests"
	@echo "clean:  Get rid of scratch and byte files"
	@echo
	@echo "Platform independent distribution/installtion related targets:"
	@echo "source:   Create source package"
	@echo "install:  Install on local system"
	@echo
	@echo "RPM related targets:"
	@echo "srpm:  Generate a source RPM package (.srpm)"
	@echo "rpm:   Generate binary RPMs"
	@echo
	@echo "Debian related targets:"
	@echo "deb:      Generate both source and binary debian packages"
	@echo "deb-src:  Generate a source debian package"
	@echo "deb-bin:  Generate a binary debian package"
	@echo
	@echo "Release related targets:"
	@echo "source-release:  Create source package for the latest tagged release"
	@echo "srpm-release:    Generate a source RPM package (.srpm) for the latest tagged release"
	@echo "rpm-release:     Generate binary RPMs for the latest tagged release"


source: clean
	if test ! -d SOURCES; then mkdir SOURCES; fi
	git archive --prefix="avocado-virt-$(COMMIT)/" -o "SOURCES/avocado-virt-$(VERSION)-$(SHORT_COMMIT).tar.gz" HEAD

source-release: clean
	if test ! -d SOURCES; then mkdir SOURCES; fi
	git archive --prefix="avocado-virt-$(RELEASE_COMMIT)/" -o "SOURCES/avocado-virt-$(VERSION)-$(RELEASE_SHORT_COMMIT).tar.gz" $(VERSION)

install:
	$(PYTHON) setup.py install --root $(DESTDIR) $(COMPILE)

prepare-source:
	# build the source package in the parent directory
	# then rename it to project_version.orig.tar.gz
	dch -D "vivid" -M -v "$(VERSION)" "Automated (make builddeb) build."
	$(PYTHON) setup.py sdist $(COMPILE) --dist-dir=../ --prune
	rename -f 's/$(PROJECT)-(.*)\.tar\.gz/$(PROJECT)_$$1\.orig\.tar\.gz/' ../*

deb-src: prepare-source
	# build the source package
	dpkg-buildpackage -S -elookkas@gmail.com -rfakeroot

deb-bin: prepare-source
	# build binary package
	dpkg-buildpackage -b -rfakeroot

deb: prepare-source
	# build both source and binary packages
	dpkg-buildpackage -i -I -rfakeroot

srpm: source
	if test ! -d BUILD/SRPM; then mkdir -p BUILD/SRPM; fi
	mock --resultdir BUILD/SRPM -D "commit $(COMMIT)" --buildsrpm --spec avocado-virt.spec --sources SOURCES

rpm: srpm
	if test ! -d BUILD/RPM; then mkdir -p BUILD/RPM; fi
	mock --resultdir BUILD/RPM -D "commit $(COMMIT)" --rebuild BUILD/SRPM/avocado-virt-$(VERSION)-*.src.rpm

srpm-release: source-release
	if test ! -d BUILD/SRPM; then mkdir -p BUILD/SRPM; fi
	mock --resultdir BUILD/SRPM -D "commit $(RELEASE_COMMIT)" --buildsrpm --spec avocado-virt.spec --sources SOURCES

rpm-release: srpm-release
	if test ! -d BUILD/RPM; then mkdir -p BUILD/RPM; fi
	mock --resultdir BUILD/RPM -D "commit $(RELEASE_COMMIT)" --rebuild BUILD/SRPM/avocado-virt-$(VERSION)-*.src.rpm

check:
	selftests/checkall
clean:
	$(PYTHON) setup.py clean
	$(MAKE) -f $(CURDIR)/debian/rules clean || true
	rm -rf build/ MANIFEST BUILD BUILDROOT SPECS RPMS SRPMS SOURCES
	find . -name '*.pyc' -delete

link:
	ln -sf ../../../../$(DIRNAME)/etc/avocado/conf.d/virt.conf ../$(AVOCADO_DIRNAME)/etc/avocado/conf.d/
	$(PYTHON) setup.py develop --user

unlink:
	$(PYTHON) setup.py develop --uninstall --user
	test -L ../$(AVOCADO_DIRNAME)/etc/avocado/conf.d/virt.conf && rm -f ../$(AVOCADO_DIRNAME)/etc/avocado/conf.d/virt.conf || true
