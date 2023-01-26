### FUNCTIONS
define rwildcard
    $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
endef

### VARIABLES
export HUGOBASEDIR := $(ORGMODE_DIRECTORY)/publisher/hugo
export HUGOPOSTDIR := $(HUGOBASEDIR)/content/posts
export HUGOIMAGEDIR := $(HUGOBASEDIR)/static/images

HUGOGENDIR := $(ORGMODE_BUILDIR)/hugogen
orgobjects := $(call rwildcard,$(ORGMODE_FILEDIR),*.org)

### TARGETS
.PHONY: post site deploy clean cleanall

post:
	@mkdir -p $(HUGOPOSTDIR) $(HUGOIMAGEDIR)
	@bash $(ORGMODE_SCRIPTDIR)/blog-export-hugo.el $(orgobjects)

site:
	@hugo -e production -v --gc -s $(HUGOBASEDIR) -d $(HUGOGENDIR)

clean:
	@rm -rf $(HUGOGENDIR)/*

cleanall: clean
	@rm -rf $(HUGOPOSTDIR) $(HUGOIMAGEDIR)
