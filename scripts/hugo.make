### FUNCTIONS
define rwildcard
    $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
endef

### VARIABLES
export HUGOBASEDIR := $(ORGMODE_DIRECTORY)/publisher/hugo
export HUGOPOSTDIR := $(HUGOBASEDIR)/content/posts
export HUGOIMAGEDIR := $(HUGOBASEDIR)/static/images

export HUGOGENDIR := $(ORGMODE_BUILDIR)/hugogen
orgobjects := $(call rwildcard,$(ORGMODE_FILEDIR),*.org)

### TARGETS
.PHONY: post site deploy clean cleanall

post:
	@mkdir -p $(HUGOPOSTDIR) $(HUGOIMAGEDIR)
	@bash $(ORGMODE_SCRIPTDIR)/blog-export-hugo.el $(orgobjects)

site:
	@if ! [ -e $(HUGOGENDIR) ]; then \
		mkdir -p $(HUGOGENDIR); \
		git -C $(HUGOGENDIR) init --initial-branch=hugo; \
		git -C $(HUGOGENDIR) remote add origin codeberg:GinShio/ginshio.codeberg.page.git; \
		git -C $(HUGOGENDIR) remote set-url --add --push origin codeberg:GinShio/ginshio.codeberg.page.git; \
		git -C $(HUGOGENDIR) remote set-url --add --push origin github:GinShio/ginshio.github.io.git; \
		git -C $(HUGOGENDIR) remote set-url --add --push origin bitbucket:GinShio/GinShio.bitbucket.io.git; \
		git -C $(HUGOGENDIR) remote set-url --add --push origin gitlab:GinShio/ginshio.gitlab.io.git; \
		git -C $(HUGOGENDIR) pull origin hugo; \
	fi
	@hugo --environment production --logLevel info --gc --source $(HUGOBASEDIR) --destination $(HUGOGENDIR)

clean:
	@rm -rf $(HUGOGENDIR)/*

cleanall: clean
	@rm -rf $(HUGOPOSTDIR) $(HUGOIMAGEDIR)
