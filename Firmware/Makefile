GPASM ?= gpasm
PYTHON ?= python3
BUILD_DIR ?= build
CALLSIGN ?= N0PUF

SOURCE := foxmox-v2.6.asm
OUTPUT_DIR := $(BUILD_DIR)
CALLSIGN_INCLUDE := $(OUTPUT_DIR)/generated-callsign.inc
GPASM_IMAGE := $(OUTPUT_DIR)/foxmox-v2.6-gpasm.hex
EXACT_IMAGE := $(OUTPUT_DIR)/foxmox-v2.6.hex
REFERENCE := foxmox-v2.6.hex

.PHONY: all image verify test clean FORCE require-default-callsign

all: verify

image: $(EXACT_IMAGE)
	@echo "Built $(EXACT_IMAGE) for callsign $(CALLSIGN)"

$(CALLSIGN_INCLUDE): emit_callsign.py FORCE
	mkdir -p $(OUTPUT_DIR)
	$(PYTHON) emit_callsign.py --callsign "$(CALLSIGN)" --output $@

$(GPASM_IMAGE): $(SOURCE) $(CALLSIGN_INCLUDE)
	mkdir -p $(OUTPUT_DIR)
	$(GPASM) -I $(OUTPUT_DIR) -o $@ $<

$(EXACT_IMAGE): $(GPASM_IMAGE) canonicalize_hex.py
	$(PYTHON) canonicalize_hex.py $< $@

require-default-callsign:
	@test "$(CALLSIGN)" = "N0PUF" || { \
		echo "ERROR: exact verification applies only to CALLSIGN=N0PUF; use 'make image CALLSIGN=$(CALLSIGN)'" >&2; \
		exit 2; \
	}

verify: require-default-callsign test $(EXACT_IMAGE) verify_image.py $(REFERENCE)
	$(PYTHON) verify_image.py $(GPASM_IMAGE)
	cmp $(EXACT_IMAGE) $(REFERENCE)
	@echo "PASS canonical Intel HEX is byte-for-byte identical"

test:
	$(PYTHON) -m unittest -v test_emit_callsign.py

clean:
	rm -rf $(BUILD_DIR) __pycache__

FORCE:
