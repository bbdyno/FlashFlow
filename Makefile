# Make targets for Tuist workflow
.PHONY: install clean

install:
	tuist install
	tuist generate

clean:
	tuist clean
