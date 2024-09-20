### VARIABLES
TIKZSRCDIR := $(ORGMODE_FILEDIR)/images
TIKZGENDIR := $(ORGMODE_BUILDIR)/tikzgen
TIKZTMPDIR := $(shell mkdir -p $(XDG_RUNTIME_DIR)/emacs && mktemp -d -q $(XDG_RUNTIME_DIR)/emacs/tikz.XXXXXXXXXX)

texobjects := $(notdir $(wildcard $(TIKZSRCDIR)/*.tex))
svgobjects := $(patsubst %.tex,%.svg,$(texobjects))

### VPATH
vpath
vpath %.tex $(TIKZSRCDIR)
vpath %.pdf $(TIKZTMPDIR)
vpath %.svg $(TIKZGENDIR)

### TARGETS
.PHONY: all clean cleanall

all: $(svgobjects)

cleanall:
	@rm -rf $(TIKZGENDIR)

$(svgobjects): %.svg: %.tex
	@latexmk -use-make -silent -lualatex -outdir=$(TIKZTMPDIR) $<
	@inkscape --pdf-poppler \
		--export-type=svg --export-text-to-path --export-area-drawing \
		--export-filename $(TIKZGENDIR)/$@ $(TIKZTMPDIR)/$(@:.svg=.pdf)
