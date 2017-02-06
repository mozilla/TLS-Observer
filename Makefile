# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

BUILDREF	:= $(shell git log --pretty=format:'%h' -n 1)
BUILDDATE	:= $(shell date +%Y%m%d)
BUILDENV	:= dev
BUILDREV	:= $(BUILDDATE)+$(BUILDREF).$(BUILDENV)

# Supported OSes: linux darwin windows
# Supported ARCHes: 386 amd64
OS			:= linux
ARCH		:= amd64

ifeq ($(OS),windows)
	BINSUFFIX   := ".exe"
else
	BINSUFFIX	:= ""
endif
GO 			:= GOOS=$(OS) GOARCH=$(ARCH) go
GOGETTER	:= GOPATH=$(shell pwd)/.tmpdeps go get -d
GOLDFLAGS	:= -ldflags "-X main.version=$(BUILDREV)"

all: test tlsobs-scanner tlsobs-api tlsobs tlsobs-runner

tlsobs-scanner:
	echo building TLS Observatory Scanner for $(OS)/$(ARCH)
	$(GO) build $(GOOPTS) -o $(GOPATH)/bin/tlsobs-scanner$(BINSUFFIX) $(GOLDFLAGS) github.com/mozilla/tls-observatory/tlsobs-scanner

tlsobs-api:
	echo building tlsobs-api for $(OS)/$(ARCH)
	$(GO) build $(GOOPTS) -o $(GOPATH)/bin/tlsobs-api$(BINSUFFIX) $(GOLDFLAGS) github.com/mozilla/tls-observatory/tlsobs-api

tlsobs:
	echo building tlsobs client for $(OS)/$(ARCH)
	$(GO) build $(GOOPTS) -o $(GOPATH)/bin/tlsobs$(BINSUFFIX) $(GOLDFLAGS) github.com/mozilla/tls-observatory/tlsobs

tlsobs-runner:
	echo building tlsobs-runner for $(OS)/$(ARCH)
	$(GO) build $(GOOPTS) -o $(GOPATH)/bin/tlsobs-runner$(BINSUFFIX) $(GOLDFLAGS) github.com/mozilla/tls-observatory/tlsobs-runner

vendor:
	govend -u

test:
	$(GO) test github.com/mozilla/tls-observatory/worker/mozillaEvaluationWorker/
	$(GO) test github.com/mozilla/tls-observatory/tlsobs-runner

truststores:
	cd truststores && git pull origin master && cd ..
	cat truststores/data/apple/snapshot/*.pem > conf/truststores/CA_apple_latest.crt
	cat truststores/data/java/snapshot/*.pem > conf/truststores/CA_java.crt
	curl -o conf/truststores/CA_AOSP.crt https://pki.google.com/roots.pem
	$(GO) run tools/retrieveTruststoreFromCADatabase.go mozilla > conf/truststores/CA_mozilla_nss.crt
	$(GO) run tools/retrieveTruststoreFromCADatabase.go microsoft > conf/truststores/CA_microsoft.crt

cipherscan:
	cd cipherscan && git pull origin master && cd ..

ciscotop1m:
	wget http://s3-us-west-1.amazonaws.com/umbrella-static/top-1m.csv.zip
	unzip top-1m.csv.zip
	mv top-1m.csv conf/
	rm top-1m.csv.zip

.PHONY: all test clean tlsobs-scanner tlsobs-api tlsobs-runner tlsobs vendor truststores cipherscan
