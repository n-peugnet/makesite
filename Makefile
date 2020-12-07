# Makesite

# Copyright (C) 2020  Nicolas Peugnet

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# See <https://www.gnu.org/licenses/gpl-3.0.txt> for the full text of the
# GNU General Public License version 3.0.

################################## Principles ##################################

# Makesite is a static-site-generator based on a mere Makefile.
# The content of the website must be located in a directory called `pages`.
# The result of the compilation will be located in the `public` directory.
# During the compilation, Makesite will keep intermediate files in the `build`
# directory. This way it does not have to recompile everything on each call.
# If an `assets` directory is present, every `*.js`, `*.css` files and the
# `favicon.*` it contains are automaticaly added to all pages.
# Lastly the `templates` directory contains the view and layout files in their
# respective folders.

# Here is a summary of the tree structure's directories:
#     .
#     ├── Makefile                # This file
#     ├── assets                  # Global assets files
#     ├── build                   # Intermediate build files
#     ├── pages                   # Pages content
#     ├── public                  # Public website root
#     └── templates
#         ├── layout              # Layout files
#         └── view                # View files

# In the `pages` directory, *every folder is a page*. Thus a *page's URL is its
# path*. The content of a page is rendered from every `.md` and `.html` files it
# contains, to which a list of the subpages is appended.

# There is only one exceptions to this principle: each page can have a special
# `assets` folder. As for the root one, every `*.js`, `*.css` files and the
# `favicon.*` it contains are automatically added to the associated page.

# Each page can contain a `config` file to override the default variables. Here
# is a sample page's `config` file containing all the variables you can define
# inside (all of them are optional):
#
#     title = Home
#     layout = default.html
#     view = list.html
#     date = 1607360120
#     keywords = makefile,static-site-generator
#     description = Home page of the Makesite's website

# There is a "root `config` file" at the same level as this file that contains
# the website's global configuration. Here are the variables that can be set
# inside:
#
#     sitename = Makesite
#     basepath = some/sub/folder

################################# Dependencies #################################

# Makesite requires the following programs to be in the PATH:
# - make <https://www.gnu.org/software/make/> (obviously)
# - coreutils <https://www.gnu.org/software/coreutils/>
# - sed <https://www.gnu.org/software/sed/>

# These programs are optional dependencies for some features to work properly:
# - cmark <https://github.com/commonmark/cmark> for markdown files rendering.

#################################### Usage #####################################

# Simply copy and paste this file in the directory of your website sources then
# run:
#     make site

################################# Limitations ##################################

# A static-site-generator based on a Makefile is not really the sanest idea.
# This is why Makesite has some serious limitations. Here is the full list:
# - The ` ` character is not allowed in any file or folder name (and the use
#   of any special character is strongly discouraged). It is recommended to
#   replace it with `-`.
# - The `~` character is not allowed in `config` files, as it is the one used
#   for sed in Makesite.
# - The name `assets` is reserved and cannot be used as a page name.

include config

# default config values
export sitename       ?=
export basepath       := $(subst //,/,/$(basepath)/)

################################# SubMakefile ##################################

define SUB_MAKEFILE
PAGE        := $*
PAGE_DIR    := $$(PREVDIR)/$<
ROOT_CONFIG := $$(PREVDIR)/config
CONFIG_FILE := $$(PAGE_DIR)/config
TAGS_FILE   := $$(PAGE_DIR)/tags
include $$(CONFIG_FILE)

# default config values
title       ?= $$(notdir $$(PAGE_DIR))
layout      ?= default.html
view        ?= list.html
date        ?= $$(shell stat -c %Y $$(PAGE_DIR))
keywords    ?=
description ?=

# sanitize values
description := $$(strip $$(subst ',,$$(description)))

SUBPAGES    := $$(shell find $$(PAGE_DIR) -maxdepth 1 -mindepth 1 -type d \
                             \! -name assets)
SUBMETADATA := $$(patsubst $$(PAGE_DIR)/%,%/metadatas,$$(SUBPAGES))
LAYOUT_FILE := $$(PREVDIR)/templates/layout/$$(layout)
VIEW_FILE   := $$(PREVDIR)/templates/view/$$(view)
PAGE_HTML   := $$(wildcard $$(PAGE_DIR)/*.html)
PAGE_MD     := $$(wildcard $$(PAGE_DIR)/*.md)
RENDERED_MD := $$(patsubst $$(PAGE_DIR)/%.md,%.md.html,$$(PAGE_MD))
ALL_HTML    := $$(PAGE_HTML) $$(RENDERED_MD)

JS      := $$(wildcard $$(PAGE_DIR)/assets/*.js)
CSS     := $$(wildcard $$(PAGE_DIR)/assets/*.css)
ICO     := $$(firstword $$(wildcard $$(PAGE_DIR)/assets/favicon.*))
ICO_EXT := $$(subst .,,$$(suffix $$(ICO)))
ASSETS  := $$(JS) $$(CSS) $$(ICO)

.PHONY: all
all: index.html tags metadatas

index.html: head.html content.html subpages.html $$(LAYOUT_FILE) \
            $$(CONFIG_FILE) $$(ROOT_CONFIG) $(ASSETS_SRC)
	cat $$(LAYOUT_FILE) \
	| sed 's~{{sitename}}~$$(sitename)~g' \
	| sed 's~{{title}}~$$(title)~g' \
	| sed 's~{{keywords}}~$$(keywords)~g' \
	| sed 's~{{description}}~$$(description)~g' \
	| sed -e '/{{head}}/{r head.html' -e 'd}' \
	| sed -e '/{{content}}/{r content.html' -e 'd}' \
	| sed -e '/{{subpages}}/{r subpages.html' -e 'd}' \
	> $$@

head.html: HEAD_JS =$$(JS:$$(PAGE_DIR)/%=<script src="%" async></script>)
head.html: HEAD_CSS=$$(CSS:$$(PAGE_DIR)/%=<link href="%" rel="stylesheet"/>)
head.html: HEAD_ICO=$$(ICO:$$(PAGE_DIR)/%=<link href="%" rel="icon" \
                                          type="image/$$(ICO_EXT)"/>)
head.html: $$(PREVDIR)/build/head.html $$(ASSETS)
	cp $$< $$@
	echo '$$(HEAD_JS) $$(HEAD_CSS) $$(HEAD_ICO)' >> $$@

content.html: $$(ALL_HTML)
	if [ -n '$$^' ]; then cat $$^ > $$@; else touch $$@; fi

%.md.html: $$(PAGE_DIR)/%.md
	cmark $$< > $$@

subpages.html: $$(SUBMETADATA)
	echo '<ul>' > $$@
	for f in $$^; \
	do \
		title=$$$$(cut -f1 $$$$f); \
		date=$$$$(cut -f2 $$$$f); \
		description=$$$$(cut -f3 $$$$f); \
		path=$$$$(cut -f4 $$$$f); \
		cat $$(VIEW_FILE) \
		| sed "s~{{title}}~$$$$title~g" \
		| sed "s~{{date}}~$$$$date~g" \
		| sed "s~{{description}}~$$$$description~g" \
		| sed "s~{{path}}~$$(basepath)$$$$path~g" \
		>> $$@; \
	done
	echo '</ul>' >> $$@

%/metadatas: .FORCE
	@$$(MAKE) -C $$(PREVDIR) $$(subst //,/,public/$$(PAGE)/$$*/index.html)

metadatas: $$(CONFIG_FILE)
	echo '$$(title)	$$(date)	$$(description)	$$(PAGE)' > $$@

tags: $$(TAGS_FILE)
	cat $$< \
	| sed 's~$$$$~ $$(PAGE)~g' \
	> $$@

$$(TAGS_FILE):
	touch $$@

$$(CONFIG_FILE):
	touch $$@

.FORCE:
endef

############################### Default template ###############################

define DEFAULT_TEMPLATE
<!DOCTYPE html>
<html>
	<head>
		<title>{{title}} - {{sitename}}</title>
		<meta charset="utf-8" />
		<meta name="viewport" content="width=device-width" />
		<meta name="Revisit-After" content="15 days"/>
		<meta name="Robots" content="All"/>
		<meta name="Title" content="{{title}} - {{sitename}}"/>
		<meta name="Keywords" content="{{keywords}}"/>
		<meta name="Description" content="{{description}}"/>
		{{head}}
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

############################### Default listview ###############################

define DEFAULT_LISTVIEW
<li>
	<p>
		<a href="{{path}}">{{title}}</a>
	</p>
	<p>{{description}}</p>
</li>
endef

################################ Main Makefile #################################

PAGES_LIST     := $(shell find pages -mindepth 1 -type d \! -name assets)
PUBLIC_PAGES   := $(patsubst pages/%,public/%,$(PAGES_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES))

JS         := $(wildcard assets/*.js)
CSS        := $(wildcard assets/*.css)
ICO        := $(firstword $(wildcard assets/favicon.*))
ICO_EXT    := $(subst .,,$(suffix $(ICO)))
PUBLIC_JS  := $(JS:%=public/%)
PUBLIC_CSS := $(CSS:%=public/%)
PUBLIC_ICO := $(ICO:%=public/%)
ASSETS     := $(PUBLIC_JS) $(PUBLIC_CSS) $(PUBLIC_ICO)

ASSETS_DIR := $(shell find pages -mindepth 1 -type d -name assets)
SUB_JS     := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.js))
SUB_CSS    := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.css))
SUB_ICO    := $(foreach d,$(ASSETS_DIR),$(firstword $(wildcard $(d)/favicon.*)))
PUBLIC_SUB_JS  := $(SUB_JS:pages/%=public/%)
PUBLIC_SUB_CSS := $(SUB_CSS:pages/%=public/%)
PUBLIC_SUB_ICO := $(SUB_ICO:pages/%=public/%)
SUB_ASSETS := $(PUBLIC_SUB_JS) $(PUBLIC_SUB_CSS) $(PUBLIC_SUB_ICO)

.PHONY: site
site: templates/layout/default.html templates/view/list.html \
      build/head.html $(SUB_ASSETS) public/index.html

build/head.html: HEAD_JS =$(JS:%=<script src="$(basepath)%" async></script>)
build/head.html: HEAD_CSS=$(CSS:%=<link href="$(basepath)%" rel="stylesheet"/>)
build/head.html: HEAD_ICO=$(ICO:%=<link href="$(basepath)%" rel="icon" \
                                   type="image/$(ICO_EXT)"/>)
build/head.html: $(ASSETS)
	echo '$(HEAD_JS) $(HEAD_CSS) $(HEAD_ICO)' > $@

public/assets/%: assets/% build public/assets
	cp $< $@

$(SUB_ASSETS): public/%: pages/%
	mkdir -p $(@D)
	cp $< $@

public/index.html: build/pages/index.html public
	cp $< $@

.PRECIOUS: build/pages/index.html
build/pages/index.html: build/pages/Makefile .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

.PRECIOUS: build/pages/Makefile
build/pages/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/Makefile: pages Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

public/%/index.html: build/pages/%/index.html public/%
	cp $< $@

.PRECIOUS: build/pages/%/index.html
build/pages/%/index.html: build/pages/%/Makefile .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

.PRECIOUS: build/pages/%/Makefile
build/pages/%/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/%/Makefile: pages/% Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

# base folders needed
build public pages public/assets:
	mkdir -p $@

templates/layout/default.html: export CONTENT=$(DEFAULT_TEMPLATE)
templates/layout/default.html: Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@


templates/view/list.html: export CONTENT=$(DEFAULT_LISTVIEW)
templates/view/list.html: Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

config:
	touch $@

$(PUBLIC_PAGES):
	mkdir -p $@

.PHONY: clean
clean: siteclean buildclean

.PHONY: buildclean
buildclean:
	rm -rf build
	rm -rf templates/layout/default.html
	rm -rf templates/view/list.html

.PHONY:
siteclean:
	rm -rf public

.FORCE:
