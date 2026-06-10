BIBS := $(wildcard bibliography/*.bib)
TEXS := $(wildcard *.tex) $(wildcard */*.tex)

# require commandline STYLE arg for usage
# ifndef STYLE
# $(error STYLE variable is required. Usage: make docx STYLE=apa)
# endif

# badly grab the parent dir name
PARENT_DIR := $(notdir $(patsubst %/,%,$(dir $(CURDIR))))

# define variables in use
CSL_DIR := styles/csl
CSL := $(CSL_DIR)/$(STYLE).csl

PROJECT := $(notdir $(CURDIR))
OUT ?= $(CURDIR)/styles/$(MAKECMDGOALS)/$(PROJECT)-$(STYLE)

ZOTERO_STYLE_URL := https://www.zotero.org/styles/$(STYLE)

# check if style has been defined
styleCheck:
	@if [ -z "$(STYLE)" ]; then \
		echo "Error: STYLE variable is required. Usage: make $(MAKECMDGOALS) STYLE=apa"; \
		exit 1;	\
	fi

# check if a valid reference docx exists, if not, make it using
# pandocs template for reference documents
checkReference: | styles/reference
	@if [ ! -f "styles/reference/$(STYLE).docx" ]; then \
		echo "Output file does not exist; creating placeholder"; \
		pandoc --print-default-data-file reference.docx > "styles/reference/$(STYLE).docx"; \
	fi

# download the csl for the relevant style if it exists, if not crash
$(CSL):
	@curl --head --silent --fail "$(ZOTERO_STYLE_URL)" > /dev/null || \
		( echo "Error: Zotero style '$(STYLE)' does not exist at $(ZOTERO_STYLE_URL)"; exit 1 )
	mkdir -p "$(CSL_DIR)"
	curl -L -o "$(CSL)" "$(ZOTERO_STYLE_URL)"

# make the subdir
styles/docx:
	mkdir -p $@
styles/reference:
	mkdir -p $@
styles/md:
	mkdir -p $@
styles/html:
	mkdir -p $@

# transalate it across, run pandoc
docx: styleCheck $(CSL) | styles/docx checkReference
	pandoc $(TEXS) 			\
		--from latex 		\
		--to docx 			\
		--output="$(OUT).docx" 	\
		--reference-doc=styles/reference/"$(STYLE).docx" \
		$(foreach bib,$(BIBS),--bibliography="$(bib)") \
		--citeproc 			\
		--csl="$(CSL)"

md: styleCheck $(CSL) | styles/md
	pandoc $(TEXS) 			\
		--from latex \
		--to markdown-citations \
		$(foreach bib,$(BIBS),--bibliography="$(bib)") \
		--csl="$(CSL)" \
		--citeproc 			\
		--output="$(OUT).md" 	

html: styleCheck $(CSL) | styles/html
	pandoc $(TEXS) \
		--from latex \
		--to html \
		$(foreach bib,$(BIBS),--bibliography="$(bib)") \
		--csl="$(CSL)" \
		--citeproc \
		--output="$(OUT).html" 	
