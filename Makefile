APP_NAME := LeoLauncher
CONFIGURATION ?= release

.PHONY: build app dmg release install run clean

build:
	swift build -c $(CONFIGURATION)

app: build
	./Scripts/package-app.sh

dmg:
	./Scripts/make-dmg.sh

release: dmg

install: app
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "dist/$(APP_NAME).app" "/Applications/$(APP_NAME).app"
	@echo "Installed /Applications/$(APP_NAME).app"

run: install
	open "/Applications/$(APP_NAME).app"

clean:
	rm -rf .build dist Packaging/AppIcon.iconset Packaging/AppIcon.icns
