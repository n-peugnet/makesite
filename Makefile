PAGES_LIST     := $(shell find pages/* -type d)
PUBLIC_PAGES   := $(patsubst pages/%,public/%,$(PAGES_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES))

define SUB_MAKEFILE
LAYOUT_NAME := default.html
LAYOUT_FILE := $$(PREVDIR)/templates/layout/$$(LAYOUT_NAME)
PAGE_DIR    := $$(PREVDIR)/$<
PAGE_HTML   := $$(shell find $$(PAGE_DIR) -type f -name "*.html")
HTML        := $$(patsubst $$(PAGE_DIR)/%,part.%,$$(PAGE_HTML))

index.html: content.html $$(LAYOUT_FILE)
	sed -e '/{{content}}/{r $$<' -e 'd}' $$(LAYOUT_FILE) > $$@

content.html: $$(PAGE_HTML)
	cat $$^ > $$@
endef

define DEFAULT_TEMPLATE
<!DOCTYPE html>
<html>
<head>
	<title>{{title}}</title>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width" />
	<meta name="Revisit-After" content="15 days"/>
	<meta name="Robots" content="All"/>
	<meta name="Title" content="{{title}}"/>
</head>
<body>
	<section>
			<h1>{{title}}</h1>
			{{content}}
	</section>
</body>
</html>
endef

.PHONY: site
site: templates/layout/default.html $(PUBLIC_INDEXES)

public/%/index.html: build/%/index.html public/%
	cp $< $@

.PRECIOUS: build/%/index.html
build/%/index.html: build/%/Makefile .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

.PRECIOUS: build/%/Makefile
build/%/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/%/Makefile: pages/% Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

templates/layout/default.html: export CONTENT=$(DEFAULT_TEMPLATE)
templates/layout/default.html: Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

$(PUBLIC_PAGES):
	mkdir -p $@

.PHONY: clean
clean: siteclean buildclean

.PHONY: buildclean
buildclean:
	rm -rf build
	rm -rf templates/layout/default.html

.PHONY:
siteclean:
	rm -rf public

.FORCE:
