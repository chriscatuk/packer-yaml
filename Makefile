.DEFAULT_GOAL := help
SHELL := /bin/bash
.ONESHELL:

help:
	@echo "debug -- enable Ansible debug mode ("-vvv")"
	@echo "debug_full-- enable Ansible debug mode ("-vvvv")"

ifneq (,$(findstring debug,$(MAKECMDGOALS)))
ANSIBLE_OPTS=-vvv
endif

ifneq (,$(findstring debug_full,$(MAKECMDGOALS)))
ANSIBLE_OPTS=-vvvv
endif

ANSIBLE=ansible-playbook $(ANSIBLE_OPTS) -i 'localhost,'
PACKER=packer
AUTO_ROOT=$(shell pwd)
region=eu-west-1
TMPDIR := $(shell mktemp -d)

debug:
	# empty to make make happy

image-build: 
	@#use packer to build AMI

	vpc=`niet network.accounts.$(env).build.vpc $(AUTO_ROOT)/config/vpc.yml `
	subnet=`niet network.accounts.$(env).build.subnet $(AUTO_ROOT)/config/vpc.yml `

	# run ansible ...
	AWS_PROFILE=$(env) AWS_REGION=$(region) $(ANSIBLE) $(AUTO_ROOT)/config/create-image.yml -e @$(AUTO_ROOT)/config/env_dev.yml  \
	-e @$$app \
	-e app_filepath=$(app) \
	-e ansible_dir="$(AUTO_ROOT)" \
	-e tmpdir="$(TMPDIR)"
	
	if [ ! $$? -eq 0 ] ; then
	    exit 1
	fi
	cat /tmp/$(tmpkey)genimage.json
	
	$(PACKER) version

	AWS_PROFILE=$(env) AWS_MAX_ATTEMPTS=150 AWS_POLL_DELAY_SECONDS=60 $(PACKER) build -color=false  $(TMPDIR)/genimage.json
	if [ $$? -eq 0 ] ; then
	  id=`cat manifest.json | jq -r '.builds[-1].artifact_id' |  cut -d':' -f2`
	  echo "AMI $$id for $(IMAGE) was built from $(GITREPO)/$(GITBRANCH)/$(GITHASH)"
	else
	  echo "Error running packer build!"
	  exit 1
	fi
