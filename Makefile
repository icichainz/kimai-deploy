REMOTE_USER = root
REMOTE_HOST = 38.242.231.130
REMOTE_DIR  = /workspace/timesheet-dep/
LOCAL_DIR   = ./

EXCLUDES = --exclude '.git' 

.PHONY: push
push:
	rsync -avz --progress $(EXCLUDES) $(LOCAL_DIR) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)

.PHONY: run
run:
	python3 manage.py runserver 12000

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make push         - Deploy to remote server via rsync"
