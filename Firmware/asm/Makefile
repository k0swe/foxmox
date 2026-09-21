GPASM ?= gpasm
PYTHON ?= python3
BUILD_DIR ?= build
SOURCE := foxmox-v2.6.asm
GPASM_IMAGE := $(BUILD_DIR)/foxmox-v2.6-gpasm.hex
EXACT_IMAGE := $(BUILD_DIR)/foxmox-v2.6.hex
REFERENCE := ../foxmox-v2.6.hex

.PHONY: all verify clean

all: verify

$(GPASM_IMAGE): $(SOURCE)
	mkdir -p $(BUILD_DIR)
	$(GPASM) -o $@ $<

$(EXACT_IMAGE): $(GPASM_IMAGE) canonicalize_hex.py verify_image.py
	$(PYTHON) canonicalize_hex.py $< $@

verify: $(EXACT_IMAGE) verify_image.py $(REFERENCE)
	$(PYTHON) verify_image.py $(GPASM_IMAGE)
	cmp $(EXACT_IMAGE) $(REFERENCE)
	@echo "PASS canonical Intel HEX is byte-for-byte identical"

clean:
	rm -rf $(BUILD_DIR) __pycache__
