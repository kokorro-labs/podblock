BINARY = podblock
SRC = Sources/podblock.swift
BUILD_DIR = .build
INSTALL_DIR = $(HOME)/bin
PLIST_SRC = LaunchAgent/com.local.podblock.plist
PLIST_DST = $(HOME)/Library/LaunchAgents/com.local.podblock.plist

.PHONY: build install uninstall clean run

build:
	@mkdir -p $(BUILD_DIR)
	swiftc -O -framework CoreAudio -framework Foundation $(SRC) -o $(BUILD_DIR)/$(BINARY)
	@echo "Built $(BUILD_DIR)/$(BINARY)"

run: build
	$(BUILD_DIR)/$(BINARY)

install: build
	@mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/$(BINARY) $(INSTALL_DIR)/$(BINARY)
	sed 's|__INSTALL_DIR__|$(INSTALL_DIR)|g' $(PLIST_SRC) > $(PLIST_DST)
	launchctl bootout gui/$$(id -u) $(PLIST_DST) 2>/dev/null || true
	launchctl bootstrap gui/$$(id -u) $(PLIST_DST)
	@echo "Installed and started $(BINARY)"
	@echo "Logs: tail -f /tmp/podblock.log"

uninstall:
	launchctl bootout gui/$$(id -u) $(PLIST_DST) 2>/dev/null || true
	rm -f $(INSTALL_DIR)/$(BINARY)
	rm -f $(PLIST_DST)
	@echo "Uninstalled $(BINARY)"

clean:
	rm -rf $(BUILD_DIR)
