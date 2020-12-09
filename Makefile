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
# Lastly the `templates` directory contains the view and layout files in their
# respective folders.

# Here is a summary of the tree structure's directories:
#     .
#     ├── Makefile                # This file
#     ├── build                   # Intermediate build files
#     ├── pages                   # Pages content
#     ├── public                  # Public website root
#     └── templates
#         ├── layout              # Layout files
#         └── view                # View files

# In the `pages` directory, *every folder is a page*. Thus a *page's URL is its
# path*. The content of a page is rendered from every `.md` and `.html` files it
# contains, to which a list of the subpages is appended.

# There is only one exception to this principle: each page can have a special
# `assets` folder. Every `*.js`, `*.css` files and the `favicon.*` it contains
# are automatically added to the associated page and all of its childrens.

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
#     layout = custom.html
#     view = title.html

################################# Dependencies #################################

# Makesite requires the following programs to be in the PATH:
# - make <https://www.gnu.org/software/make/> (obviously)
# - coreutils <https://www.gnu.org/software/coreutils/>
# - sed <https://www.gnu.org/software/sed/>

# These programs are optional dependencies for some features to work properly:
# - cmark <https://github.com/commonmark/cmark> for markdown files rendering.

################################### Tutorial ###################################

# Download the latest version of this file in an empty directory and run it:
#
#     wget https://github.com/n-peugnet/makesite/raw/master/Makefile
#     make site
#
# This will create the base directory structure detailled above and the first
# page of your website: `index.html` in the `public` directory. To browse the
# website you will have to make it accessible with a webserver.
# To add content to the home page you can add an `.html` file in the `pages`
# folder then run once again:
#
#     make site

# You can also add new directories in `pages` to create new pages.
# Makesite will automatically add links in the parent page and breadcrumbs to
# every pages to make your website fully navigable.
# For this feature to work properly you will have to set the `basepath` variable
# accordingly.

# If you deleted some files from the `pages` directory, then its better to run:
#
#     make clean site
#
# This will ensure that the deleted content is removed from your website.

################################ Customization #################################

# It is of course possible to customize the website created by a great extent.
# Any number of templates can be added in their respective folder and used in
# specific pages or all of them using the `layout` and `view` variables of the
# according `config` file.

# Styles can also be easily defined for one or a set of pages by adding `.css`
# files in the `assets` folders.

################################# Limitations ##################################

# A static-site-generator based on a Makefile is not really the sanest idea.
# This is why Makesite has some serious limitations. Here is the full list:
# - The ` ` character is not allowed in any file or folder name (and the use
#   of any special character is strongly discouraged). Instead you can use the
#   character `_` which will be converted to space in the default title.
# - The `~` character is not allowed in `config` files, as it is the one used
#   for sed in Makesite.
# - The name `assets` is reserved and cannot be used as a page name.

################################# Developement #################################

# Here is a special target to get developers started:
#
#     make dev

include config

# default config values
export sitename       ?= Makesite
export basepath       := $(subst //,/,/$(basepath)/)
export layout         ?= default.html
export view           ?= list.html

################################# SubMakefile ##################################

define SUB_MAKEFILE
PAGE        := $*
PAGE_DIR    := $$(PREVDIR)/$<
ROOT_CONFIG := $$(PREVDIR)/config
CONFIG_FILE := $$(wildcard $$(PAGE_DIR)/config)
include $$(CONFIG_FILE)

# default config values
title       ?= $(shell echo $(notdir $(subst _, ,/$<)) \
                       | awk '{$$1=toupper(substr($$1,0,1))substr($$1,2)}1')
layout      ?= default.html
view        ?= list.html
date        ?= $$(shell stat -c %Y $$(PAGE_DIR))
keywords    ?=
description ?=

# sanitize values
description := $$(strip $$(subst ',,$$(description)))

PAGESDIR    := $$(PREVDIR)/pages
PARENT      := $(patsubst pages%$(notdir $*),%,$<)
SEPARATOR   := /
SUBPAGES    := $$(shell find $$(PAGE_DIR) -maxdepth 1 -mindepth 1 -type d \
                             \! -name assets)
SUBBUILDS   := $$(SUBPAGES:$$(PAGE_DIR)/%=%)
SUBMETADATA := $$(SUBBUILDS:%=%/metadatas)
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
all: index.html

index.html: metadatas head.html breadcrumbs.html content.html subpages.html \
            $$(LAYOUT_FILE) $$(CONFIG_FILE) $$(ROOT_CONFIG) $(ASSETS_SRC)
	cat $$(LAYOUT_FILE) \
	| sed 's~{{sitename}}~$$(sitename)~g' \
	| sed 's~{{title}}~$$(title)~g' \
	| sed 's~{{keywords}}~$$(keywords)~g' \
	| sed 's~{{description}}~$$(description)~g' \
	| sed -e '/{{head}}/{r head.html' -e 'd}' \
	| sed -e '/{{breadcrumbs}}/{r breadcrumbs.html' -e 'd}' \
	| sed -e '/{{content}}/{r content.html' -e 'd}' \
	| sed -e '/{{subpages}}/{r subpages.html' -e 'd}' \
	> $$@

head.html: J=$$(JS:$$(PAGESDIR)/%=<script src="$$(basepath)%" async></script>)
head.html: C=$$(CSS:$$(PAGESDIR)/%=<link href="$$(basepath)%" rel="stylesheet">)
head.html: I=$$(ICO:$$(PAGESDIR)/%=<link href="$$(basepath)%" rel="icon" \
                                    type="image/$$(ICO_EXT)">)
head.html: ../head.html $$(ASSETS)
	cp $$< $$@
	echo '$$(J) $$(C) $$(I)' >> $$@

breadcrumbs.html: ../breadcrumbs.html $$(wildcard ../metadatas)
	cp $$< $$@
ifneq ($$(strip $$(PARENT)),)
	echo  '<a href="$$(subst //,/,/$$(basepath)$$(PARENT))"\
	       >$$(shell cut -f1 ../metadatas)</a> $$(SEPARATOR)' >> $$@
endif

content.html: $$(ALL_HTML)
	if [ -n '$$^' ]; then cat $$^ > $$@; else touch $$@; fi

%.md.html: $$(PAGE_DIR)/%.md
	cmark $$< > $$@

subpages.html: $$(SUBBUILDS) $$(VIEW_FILE) $$(CONFIG_FILE) $$(ROOT_CONFIG)
	echo '<ul>' > $$@
ifneq ($$(strip $$(SUBMETADATA)),)
	for f in $$(SUBMETADATA); \
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
endif
	echo '</ul>' >> $$@

$$(SUBBUILDS): head.html breadcrumbs.html metadatas .FORCE
	@$$(MAKE) -C $$@

metadatas: $$(CONFIG_FILE)
	echo '$$(title)	$$(date)	$$(description)	$$(PAGE)' > $$@

../head.html ../breadcrumbs.html:
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
			<p>{{breadcrumbs}}</p>
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
BUILD_MK_LIST  := $(patsubst %,build/%/Makefile,$(PAGES_LIST))
PUBLIC_PAGES   := $(patsubst pages/%,public/%,$(PAGES_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES))

ASSETS_DIR := $(shell find pages -mindepth 1 -type d -name assets)
JS     := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.js))
CSS    := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.css))
ICO    := $(foreach d,$(ASSETS_DIR),$(firstword $(wildcard $(d)/favicon.*)))
PUBLIC_JS  := $(JS:pages/%=public/%)
PUBLIC_CSS := $(CSS:pages/%=public/%)
PUBLIC_ICO := $(ICO:pages/%=public/%)
ASSETS := $(PUBLIC_JS) $(PUBLIC_CSS) $(PUBLIC_ICO)

.PHONY: site
site: pages templates/layout/default.html templates/view/list.html \
      public/index.html $(ASSETS) $(PUBLIC_INDEXES)

pages:
	mkdir $@

$(ASSETS): public/%: pages/%
	mkdir -p $(@D)
	cp $< $@

public/index.html $(PUBLIC_INDEXES): public/%: build/pages/% \
                  build/pages/index.html
	mkdir -p $(@D)
	cp $< $@

.PRECIOUS: build/pages/index.html
build/pages/index.html: build/pages/Makefile $(BUILD_MK_LIST) .FORCE
	@$(MAKE) -C $(@D) PREVDIR=$(CURDIR)

# This recipe makes the targets depend on the above recursive make call.
build/pages/%/index.html: build/pages/index.html ;

.PRECIOUS: build/pages/Makefile
build/pages/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/Makefile: pages Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

.PRECIOUS: build/pages/%/Makefile
build/pages/%/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/%/Makefile: pages/% Makefile
	mkdir -p $(@D)
	echo "$$CONTENT" > $@

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

.PHONY: clean
clean: siteclean buildclean

.PHONY: buildclean
buildclean:
	rm -rf build
	rm -rf templates/layout/default.html
	rm -rf templates/view/list.html

.PHONY: siteclean
siteclean:
	rm -rf public

.PHONY: dev
dev: .gitignore

.gitignore:
	echo '*' > $@
	echo '!Makefile' >> $@

.FORCE:
