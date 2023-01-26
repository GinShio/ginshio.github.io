### VARIABLES
TIKZSRCDIR := $(ORGMODE_FILEDIR)/images
TIKZGENDIR := $(ORGMODE_BUILDIR)/tikzgen

texobjects := $(notdir $(wildcard $(TIKZSRCDIR)/*.tex))
svgobjects := $(patsubst %.tex,%.svg,$(texobjects))

### VPATH
vpath
vpath %.tex $(TIKZSRCDIR)
vpath %.pdf $(TIKZGENDIR)
vpath %.svg $(TIKZGENDIR)

### TARGETS
.PHONY: all clean cleanall

all: $(svgobjects)

clean: %.tex
	@latexmk -c -outdir=$(TIKZGENDIR) $<

cleanall:
	@rm -rf $(TIKZGENDIR)

$(svgobjects): %.svg: %.tex
	@latexmk -use-make -silent -lualatex \
		-outdir=$(TIKZGENDIR) $<
	@inkscape --pdf-poppler --pdf-page=1 \
		--export-type=svg --export-text-to-path --export-area-drawing \
		--export-filename $(TIKZGENDIR)/$@ $(TIKZGENDIR)/$(@:.svg=.pdf)
