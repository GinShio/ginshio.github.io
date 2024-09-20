### VARIABLES
export ORGMODE_DIRECTORY := $(shell dirname $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
export ORGMODE_SCRIPTDIR := $(ORGMODE_DIRECTORY)/scripts
export ORGMODE_FILEDIR := $(ORGMODE_DIRECTORY)/blog
export ORGMODE_BUILDIR := $(ORGMODE_DIRECTORY)/_build

### TARGETS
.PHONY: all cleanall
all: tikz hugo beanencrypt

cleanall:
	@make -f $(ORGMODE_SCRIPTDIR)/tikz.make cleanall
	@make -f $(ORGMODE_SCRIPTDIR)/hugo.make cleanall
	@EXECTARGET=CLEANALL make -f $(ORGMODE_SCRIPTDIR)/beancount.make cleanall

.PHONY: tikz cleantikz
tikz:
	@make -f $(ORGMODE_SCRIPTDIR)/tikz.make all

.PHONY: hugo posthugo sitehugo cleanhugo
hugo: tikz posthugo sitehugo

posthugo:
	@make -f $(ORGMODE_SCRIPTDIR)/hugo.make post

sitehugo:
	@make -f $(ORGMODE_SCRIPTDIR)/hugo.make site

cleanhugo:
	@make -f $(ORGMODE_SCRIPTDIR)/hugo.make clean

.PHONY: beanencrypt beandecrypt
beanencrypt:
	@make -f $(ORGMODE_SCRIPTDIR)/beancount.make encrypt

beandecrypt:
	@make -f $(ORGMODE_SCRIPTDIR)/beancount.make decrypt
