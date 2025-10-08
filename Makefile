PROJECT_NAME = pymongoose
VERSION = 0.1.0

PLATFORM = $(shell uname)
CONFIG = Release
ROOT := $(PWD)
BUILD := $(ROOT)/build
SCRIPTS := $(ROOT)/scripts
THIRDPARTY = $(ROOT)/thirdparty
LIB = $(THIRDPARTY)/install/lib
DIST = $(BUILD)/dist/$(PROJECT_NAME)
ARCH=$(shell uname -m)

# variants
BUNDLED=0
MULTI=0
UNIVERSAL=0

ifeq ($(PLATFORM), Darwin)
OS = "macos"
GENERATOR ?= "-GXcode"
ifeq ($(UNIVERSAL), 1)
DIST_NAME = $(PROJECT_NAME)-$(VERSION)-macos-universal
EXTRA_OPTIONS += -DCM_MACOS_UNIVERSAL=ON
endif
else
OS = "windows"
GENERATOR ?= ""
endif

DIST_NAME = $(PROJECT_NAME)-$(VERSION)-$(OS)-$(ARCH)
DMG = $(DIST_NAME).dmg
ZIP = $(DIST_NAME).zip


.PHONY: all build clean test snap

all: build

build:
	@mkdir -p build && \
		cd build && \
		cmake $(GENERATOR) .. $(EXTRA_OPTIONS) && \
		cmake --build . --config '$(CONFIG)' && \
		cmake --install . --config '$(CONFIG)'

clean:
	rm -rf build

test:
	PYTHONPATH=$(ROOT)/src pytest tests/ -v


snap:
	@git add --all . && git commit -m 'snap' && git push
