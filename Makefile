PAGES_LIST     := $(shell find pages/* -type d)
PUBLIC_PAGES   := $(patsubst pages/%,public/%,$(PAGES_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES))

define SUB_MAKEFILE
PAGE        := $*
PAGE_DIR    := $$(PREVDIR)/$<
CONFIG_FILE := $$(PAGE_DIR)/config
TAGS_FILE   := $$(PAGE_DIR)/tags
include $$(CONFIG_FILE)

# default config values
title       ?= $$(notdir $$(PAGE_DIR))
layout      ?= default.html
date        ?= $$(shell stat -c %Y $$(PAGE_DIR))
keywords    ?=
description ?=

# sanitize values
description := $$(strip $$(subst ',,$$(description)))

SUBPAGES    := $$(shell find $$(PAGE_DIR)/* -type d)
SUBMETADATA := $$(patsubst $$(PAGE_DIR)/%,%/metadatas,$$(SUBPAGES))
LAYOUT_FILE := $$(PREVDIR)/templates/layout/$$(layout)
PAGE_HTML   := $$(wildcard $$(PAGE_DIR)/*.html)
PAGE_MD     := $$(wildcard $$(PAGE_DIR)/*.md)
RENDERED_MD := $$(patsubst $$(PAGE_DIR)/%.md,%.md.html,$$(PAGE_MD))
ALL_HTML    := $$(PAGE_HTML) $$(RENDERED_MD)

all: index.html tags metadatas

index.html: content.html subpages.html $$(LAYOUT_FILE) $$(CONFIG_FILE)
	cp $$(LAYOUT_FILE) $$@
	sed -i 's/{{title}}/$$(title)/g' $$@
	sed -i 's/{{keywords}}/$$(keywords)/g' $$@
	sed -i 's/{{description}}/$$(description)/g' $$@
	sed -i -e '/{{content}}/{r content.html' -e 'd}' $$@
	sed -i -e '/{{subpages}}/{r subpages.html' -e 'd}' $$@

content.html: $$(ALL_HTML)
	if [ -n '$$^' ]; then cat $$^ > $$@; else touch $$@; fi

%.md.html: $$(PAGE_DIR)/%.md
	cmark $$< > $$@

subpages.html: $$(SUBMETADATA)
	if [ -n '$$^' ]; then cat $$^ > $$@; else touch $$@; fi

%/metadatas: .FORCE
	@$$(MAKE) -C $$(PREVDIR) public/$$*/index.html

metadatas: $$(CONFIG_FILE)
	echo '$$(title)	$$(date)	$$(description)	$$(PAGE)' > $$@

tags: $$(TAGS_FILE)
	cp $$< $$@
	sed -i -e 's/$$$$/ $$(PAGE)/' $$@

$$(TAGS_FILE):
	touch $$@

$$(CONFIG_FILE):
	touch $$@

.FORCE:

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
	<meta name="Keywords" content="{{keywords}}"/>
	<meta name="Description" content="{{description}}"/>
</head>
<body>
	<section>
		<h1>{{title}}</h1>
		{{content}}
	</section>
	<section>
		{{subpages}}
	</section>
</body>
</html>
endef

.PHONY: site
site: templates/layout/default.html public/index.html

public/index.html: build/index.html public
	cp $< $@

.PRECIOUS: build/index.html
build/index.html: build/Makefile .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

.PRECIOUS: build/Makefile
build/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/Makefile: pages Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

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

# base folders needed
public pages:
	mkdir $@

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
