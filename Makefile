# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= .env
-include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# to override env var, e.g. to output to stdout: make IMAGE=<REPO>:<TAG> <ACTION>
LOCAL_PLATFORM_FLAG := $(shell [[ `uname -m` == "arm64" ]] && echo "--platform linux/amd64" || echo "" )


#------------------------------------------------------------------------------#

git-clone-repo: ## Git clone repo
	if [ -z "$(NEW_REPO_NAME)" ]; then echo "'NEW_REPO_NAME' var is required!"; exit 1; fi
	cd .. && \
	git clone $(ORIGIN_REPO) $(NEW_REPO_NAME) && \
	cd $(NEW_REPO_NAME) && \
	git remote set-url origin $(NEW_REPO) && \
	git remote add upstream $(ORIGIN_REPO) && \
	git push -u origin master && git push --all
	@echo "Clone has been finished! New repo: $(NEW_REPO_NAME)"
	@echo "Don't forget to config user if needed!"

git-clone-tf-module: ORIGIN_REPO=git@github.com:demmonico/terraform-app-template.git
git-clone-tf-module: NEW_REPO=git@github.com:demmonico/$(NEW_REPO_NAME).git
git-clone-tf-module: git-clone-repo ## Git clone Terraform module repo


init: ## Setup project
	git init
	pre-commit install --install-hooks


test: ## Test project
	pre-commit run --all-files


tf-init: cmd=init
tf-init: ## Init terraform
	docker run --rm -ti $(LOCAL_PLATFORM_FLAG) \
		-v $(PWD)/:/opt -w=/opt \
		hashicorp/terraform:latest \
		$(cmd)
