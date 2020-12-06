PAGES_LIST     := $(shell find pages/* -type d)
BUILD_PAGES    := $(patsubst pages/%,build/%,$(PAGES_LIST))
PUBLIC_PAGES   := $(patsubst pages/%,public/%,$(PAGES_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES))

DIRS := $(BUILD_PAGES) $(PUBLIC_PAGES)


.PHONY: site
site: $(PUBLIC_INDEXES)

public/%/index.html: build/%/index.html public/%
	cp $< $@

.PRECIOUS: build/%/index.html
build/%/index.html: build/%/Makefile .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

.PRECIOUS: build/%/Makefile
build/%/Makefile: pages/% build/%
	@echo -n 'index.html: $$(shell find $$(PREVDIR)/$< -type f -name "*.html")\n' > $@
	@echo -n '\tcat $$^ > $$@\n' >> $@

$(DIRS):
	mkdir -p $@

.PHONY: clean
clean: siteclean buildclean

.PHONY: buildclean
buildclean:
	rm -rf build

.PHONY:
siteclean:
	rm -rf public

.FORCE:
