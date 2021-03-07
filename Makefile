# Makesite

# Copyright (c) 2020-2021  Nicolas Peugnet

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
# path*. The content of a page is rendered from every `.md` and `.html` and
# image files it contains, to which a list of the subpages is appended.

# There is only one exception to this principle: each page can have a special
# `assets` folder. Every `*.js`, `*.css` files and the `favicon.*` it contains
# are automatically added to the associated page and all of its children.
# This folder can also be used to store images that wont be automatically
# included in the content.

# Each page can contain a `config` file to override the default variables. Here
# is a sample page's `config` file containing all the variables you can define
# inside (all of them are optional):
#
#     # var         example                               default
#     title       = Home                                # (capitalized dir name)
#     layout      = page                                # (root layout)
#     view        = list                                # (root view)
#     date        = 2021-04-12                          # (dir mtime)
#     keywords    = makefile,static-site-generator
#     description = Home page of the Makesite's website
#     sort        = date/desc                           # title/asc
#     feed        = 1
#     cover       = assets/image.jpg                    # assets/cover.*

# There is a "root `config` file" at the same level as this file that contains
# the website's global configuration. Here are the variables that can be set
# inside (all of them are optional):
#
#     sitename = Makesite
#     scheme = https
#     domain = club1.fr
#     basepath = some/sub/folder
#     authorname = nicolas
#     authoremail = nicolas@club1.fr
#     layout = custom
#     view = title
#     dateformat = %d/%m/%y
#     imagesext = png|gif

# It is possible to add tags to a page by adding each of them in a new line of
# its `tags` file. These tags will replace the `{{tags}}` portion of the layout
# and provides another way to browse the website.
# An atom/rss feed is generated for each tag and made autodiscoverable.

################################# Dependencies #################################

# Makesite requires the following programs to be in the PATH:
# - make <https://www.gnu.org/software/make/> (obviously)
# - coreutils <https://www.gnu.org/software/coreutils/>
# - sed <https://www.gnu.org/software/sed/>

# These programs are optional dependencies for some features to work properly:
# - cmark <https://github.com/commonmark/cmark> for markdown files rendering.
# - busybox <https://busybox.net/> for test server.
# - fswatch <https://emcrisostomo.github.io/fswatch/> for files watcher.

################################### Tutorial ###################################

# Download the latest version of this file in an empty directory and run it:
#
#     wget https://github.com/n-peugnet/makesite/raw/master/Makefile
#     make
#
# This will create the base directory structure detailled above and the first
# page of your website: `index.html` in the `public` directory. To browse the
# website you will have to make it accessible with a webserver.
# To add content to the home page you can add an `.html` file in the `pages`
# folder then run once again:
#
#     make

# You can also add new directories in `pages` to create new pages.
# Makesite will automatically add links in the parent page and breadcrumbs to
# every pages to make your website fully navigable.
# For this feature to work properly you will have to set the `basepath` variable
# accordingly.

# If you deleted some files from the `pages` directory, then its better to run:
#
#     make clean
#     make
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
# - The `$` character must be written `$$` in `config` files not to be
#   interpreted as a variable in Makesite.
# - Relative path in content (images,links,...) must start with `./` or `../`.

################################# Developement #################################

# Code style:
# - Tab is 8 spaces.
# - Max width is 80 columns.
# - Configurable variables are [a-z] other variables are SCREAMING_SNAKE_CASE.
# Here is a special target to get developers started:
#
#     make dev

ifneq ($(word 2,$(MAKECMDGOALS)),)
ifneq ($(filter clean,$(MAKECMDGOALS)),)
$(error cannot run clean and other targets at the same time)
endif
endif

include config
include build/utils.mk

# default config values
export sitename       ?= Makesite
export scheme         ?= http
export domain         ?= localhost
export baseurl        ?= $(scheme)://$(domain)
export basepath       ?=
export authorname     ?= nobody
export authoremail    ?= $(authorname)@$(domain)
export layout         ?= page
export view           ?= full
export dateformat     ?= %FT%T%:z # ISO 8601
export imagesext      ?= png|jpe?g|gif|tiff
export loglevel       ?= info # trace|debug|info|error
export testport       ?= 8000
export watchexclude   ?= /\.[^/]+(~|\.sw[a-z])$$

# sanitize values
export sitename       :=$(call esc,$(sitename))
export domain         :=$(subst /,,$(domain))
export basepath       :=$(subst //,/,/$(basepath)/)
export authorname     :=$(call esc,$(authorname))
export authoremail    :=$(call esc,$(authoremail))

export l0:=$(if $(filter trace,$(loglevel)),,@)            # trace
export l1:=$(if $(filter trace debug,$(loglevel)),,@)      # debug
export l2:=$(if $(filter trace debug info,$(loglevel)),,@) # info
MAKEFLAGS+=$(if $(filter trace debug,$(loglevel)),, --no-print-directory)
export ROOT=$(CURDIR)

################################# SubMakefile ##################################

define SUB_MAKEFILE
PAGE        := $*
PAGE_DIR    := $$(ROOT)/$<
ROOT_CONFIG := $$(ROOT)/config
UTILS_FILE  := $$(ROOT)/build/utils.mk
CONFIG_FILE := $$(wildcard $$(PAGE_DIR)/config)
TAGS_FILE   := $$(wildcard $$(PAGE_DIR)/tags)
include $$(UTILS_FILE)
include $$(CONFIG_FILE)

# default config values
title       ?= $(shell echo $(subst _, ,$(notdir /$<)) \
		       | awk '{$$1=toupper(substr($$1,0,1))substr($$1,2)}1')
layout      ?= page
view        ?= full
date        ?= @$$(shell stat -c %Y $$(PAGE_DIR))
keywords    ?=
description ?=
sort        ?= title/asc
feed        ?=
cover       ?= $$(wildcard $$(PAGE_DIR)/assets/cover.*)

# sanitize values
date        :=$$(shell date -d '$$(date)' +%s)
title       :=$$(call esc,$$(title))
keywords    :=$$(call esc,$$(keywords))
description :=$$(call esc,$$(description))
dateformat  :=$$(strip $$(dateformat))
cover       :=$$(cover:$$(PAGE_DIR)/%=%)

PAGESDIR    := $$(ROOT)/pages
PAGE_PATH    = $$(subst //,/,$$(basepath)$$(PAGE)/)
PARENT      := $(patsubst pages%$(notdir $*),%,$<)
SEPARATOR   := /
SUBPAGES    := $$(shell find $$(PAGE_DIR) -maxdepth 1 -mindepth 1 -type d \
			     \! -name assets)
SUBMETADATA := $$(SUBPAGES:$$(PAGE_DIR)/%=%/metadatas)
SORT_FIELD  := $$(subst /,,$$(dir $$(sort)))
SORT_ORDER  := $$(notdir $$(sort))
TPL_DIR     := $$(ROOT)/build/templates
LAYOUT_FILE := $$(TPL_DIR)/layout/$$(layout).html
VIEW_FILE   := $$(TPL_DIR)/view/$$(view).html
TAG_VIEW    := $$(TPL_DIR)/view/tag.html
PAGE_HTML   := $$(wildcard $$(PAGE_DIR)/*.html)
PAGE_MD     := $$(wildcard $$(PAGE_DIR)/*.md)
RENDERED_MD := $$(patsubst $$(PAGE_DIR)/%.md,%.md.html,$$(PAGE_MD))
ALL_HTML    := $$(PAGE_HTML) $$(RENDERED_MD)

JS      := $$(wildcard $$(PAGE_DIR)/assets/*.js)
CSS     := $$(wildcard $$(PAGE_DIR)/assets/*.css)
ICO     := $$(firstword $$(wildcard $$(PAGE_DIR)/assets/favicon.*))
ICO_EXT := $$(subst .,,$$(suffix $$(ICO)))
ASSETS  := $$(JS) $$(CSS) $$(ICO)

IMG := $$(shell find $$(PAGE_DIR) -maxdepth 1 | grep -E '($(imagesext))$$$$')
COVER = $$(if $$(cover),$$(call esc,<img class="cover" alt="[cover picture]" \
	src="$$(PAGE_PATH)$$(cover)" />),)

ifeq ($$(strip $$(feed)),1)
OTHER += feed.atom
endif

ifeq ($$(SORT_FIELD),title)
SORT_FLAGS = -k1
else ifeq ($$(SORT_FIELD),date)
SORT_FLAGS = -k2 -n
endif
ifeq ($$(SORT_ORDER),desc)
SORT_FLAGS += -r
endif

# Default target.
.PHONY: build/$<
build/$<: index.html metadatas tagspage $$(OTHER)
ifeq ($$(strip $$(l1)),@)
	@:
endif

index.html: head.html breadcrumbs.html tags.html content.html pages.html \
	    $$(LAYOUT_FILE) $$(CONFIG_FILE) $$(ROOT_CONFIG) $(ASSETS_SRC)
	$$(l0)sed $$(LAYOUT_FILE) \
	-e 's~{{sitename}}~$$(sitename)~' \
	-e 's~{{title}}~$$(title)~' \
	-e 's~{{cover}}~$$(COVER)~' \
	-e 's~{{keywords}}~$$(keywords)~' \
	-e 's~{{date}}~$$(shell date -d @$$(date) +'$$(dateformat)')~' \
	-e 's~{{description}}~$$(description)~' \
	-e '/{{head}}/{r head.html' -e 'd}' \
	-e '/{{breadcrumbs}}/{r breadcrumbs.html' -e 'd}' \
	-e '/{{tags}}/{r tags.html' -e 'd}' \
	-e '/{{content}}/{r content.html' -e 'd}' \
	-e '/{{pages}}/{r pages.html' -e 'd}' \
	> $$@
	$$(l1)#GEN build/$</$$@

head.html: J=$$(JS:$$(PAGESDIR)/%=<script src="$$(basepath)%" async></script>)
head.html: C=$$(CSS:$$(PAGESDIR)/%=<link href="$$(basepath)%" rel="stylesheet">)
head.html: I=$$(ICO:$$(PAGESDIR)/%=<link href="$$(basepath)%" rel="icon" \
				    type="image/$$(ICO_EXT)">)
head.html: ../head.html $$(CONFIG_FILE) | $$(ASSETS)
	$$(l0)cp $$< $$@
	$$(l0)echo '$$(J) $$(C) $$(I)' >> $$@
ifeq ($$(strip $$(feed)),1)
	$$(l0)echo '<link href="$$(PAGE_PATH)feed.atom" title="$$(title) feed" \
			  rel="alternate" type="application/atom+xml" />' >> $$@
endif
	$$(l1)#GEN build/$</$$@

breadcrumbs.html: ../breadcrumbs.html $$(wildcard ../metadatas)
	$$(l0)cp $$< $$@
ifneq ($$(strip $$(PARENT)),)
	$$(l0)printf '<a href="$$(subst //,/,$$(basepath)$$(PARENT))"\
		     >$$(shell cut -f1 ../metadatas)</a> $$(SEPARATOR) ' >> $$@
endif
	$$(l1)#GEN build/$</$$@

content.html: I=$$(IMG:$$(PAGESDIR)/%=<img src="$$(basepath)%" alt="[auto]"/>)
content.html: $$(ALL_HTML) $$(IMG)
	$$(l0)echo '$$I' > $$@
ifneq ($$(strip $$(ALL_HTML)),)
	$$(l0)cat $$(ALL_HTML) \
	      | sed -E 's~(src|href)="(\.[^"]*)"~\\1="$$(PAGE_PATH)\\2"~g' \
	      >> $$@
endif
	$$(l1)#GEN build/$</$$@

%.md.html: $$(PAGE_DIR)/%.md
	$$(l0)cmark $$< > $$@
	$$(l1)#MDC build/$</$$@

pages.html: $$(SUBMETADATA) $$(VIEW_FILE) $$(CONFIG_FILE) $$(ROOT_CONFIG)
	$$(l0)echo '<ul>' > $$@
ifneq ($$(strip $$(SUBMETADATA)),)
	$$(l0)$$(call pages,$$(SUBMETADATA),$$(VIEW_FILE),$$@,$$(dateformat), \
		      $$(SORT_FLAGS))
endif
	$$(l0)echo '</ul>' >> $$@
	$$(l1)#GEN build/$</$$@

ifeq ($$(strip $$(feed)),1)
feed.atom: pages.atom $$(TPL_DIR)/layout/feed.atom
	$$(l0)$$(call atomfeed,$$(PAGE),$$<,$$@,$$(title))
	$$(l1)#GEN $@

pages.atom: $$(TPL_DIR)/view/entry.atom $$(SUBMETADATA) \
			 $$(ROOT_CONFIG)
	$$(l0)echo > $$@
	$$(l0)$$(call pages,$$(SUBMETADATA),$$<,$$@,%FT%T%:z,-nrk2)
	$$(l1)#GEN $@
endif

$$(SUBMETADATA): head.html breadcrumbs.html metadatas .FORCE
	$$(l0)$$(MAKE) -C $$(@D)

metadatas: $$(CONFIG_FILE)
	$$(l0)echo '$$(title)\t$$(date)\t$$(description)\t$$(PAGE)\t\t$\
		    $$(COVER)' > $$@
	$$(l1)#GEN build/$</$$@

tagspage: tags breadcrumbs.html content.html $$(CONFIG_FILE)
# The last column is only there to generate a diff in build/tags
	$$(l0)cat $$< | xargs -I % echo \
		%'\t$$(title)\t$$(date)\t$$(description)\t$$(PAGE)$\
		  \t$$(shell cat breadcrumbs.html)\t$$(COVER)$\
		  \t$$(shell stat -c %Y content.html)' > $$@
	$$(l1)#GEN build/$</$$@

tags.html: tags
	$$(l0)echo '<ul>' > $$@
	$$(l0)cat $$< | while read tag; do \
		sed $$(TAG_VIEW) \
		-e "s~{{tag}}~$$$$tag~" \
		-e "s~{{path}}~$$(basepath)tags/$$$$tag~" \
		| tr -d '\\n' >> $$@; \
	done
	$$(l0)echo '</ul>' >> $$@
	$$(l1)#GEN build/$</$$@

tags: $$(TAGS_FILE)
ifneq ($$(strip $$(TAGS_FILE)),)
	$$(l0)$$(call slugify,$$(TAGS_FILE)) > $$@
	$$(l1)#SAN build/$</$$@
else
	$$(l0)touch $$@
endif

../head.html ../breadcrumbs.html:
	$$(l0)touch $$@
.FORCE:
endef

################################# Page layout ##################################

define PAGE_LAYOUT
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
		<style>
		.tags ul {padding: 0;}
		.tag {list-style-type: none; display: inline-block; margin:2px;\
padding: 2px 6px; background-color: grey; border-radius: 15px;}
		.tag a {color: white; text-decoration: none;}
		</style>
	</head>
	<body>
		<section>
			<p class="breadcrumbs">
				{{breadcrumbs}} {{title}}
			</p>
			{{cover}}
			<h1>{{title}}</h1>
			<p class="date">{{date}}</p>
			<div class="tags">
				{{tags}}
			</div>
			{{content}}
		</section>
		<section>
			{{pages}}
		</section>
	</body>
</html>
endef

################################## Tag layout ##################################

define TAG_LAYOUT
<!DOCTYPE html>
<html>
	<head>
		<title>Tag: {{tag}} - {{sitename}}</title>
		<meta charset="utf-8" />
		<meta name="viewport" content="width=device-width" />
		<link href="feed.atom" title="Tag: {{tag}} Atom feed" \
		      rel="alternate" type="application/atom+xml" />
		{{head}}
	</head>
	<body>
		<section>
			<h1>Tag: {{tag}}</h1>
			{{pages}}
		</section>
	</body>
</html>
endef

################################## Full view ###################################

define FULL_VIEW
<li>
	<p>
		{{cover}}
		{{breadcrumbs}} <a href="{{path}}">{{title}}</a>
		<span class="date">{{date}}</span>
	</p>
	<p class="description">{{description}}</p>
	<article class="content">
		{{content}}
	</article>
</li>
endef

################################### Tag view ###################################

define TAG_VIEW
<li class="tag tag-{{tag}}">
	<a href="{{path}}">{{tag}}</a>
</li>
endef

################################# Atom layout ##################################

define ATOM_LAYOUT
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>{{title}} - {{sitename}}</title>
	<link href="{{link}}" rel="self" />
	<link href="{{root}}" />
	<id>{{id}}</id>
	<updated>{{date}}</updated>
	{{pages}}
</feed>
endef

################################ Atomentry view ################################

define ATOMENTRY_VIEW
<entry>
	<title>{{title}}</title>
	<link href="{{baseurl}}{{path}}"/>
	<id>{{id}}</id>
	<updated>{{date}}</updated>
	<summary>{{description}}</summary>
	<author>
		<name>{{authorname}}</name>
		<email>{{authoremail}}</email>
	</author>
	<content type="xhtml">
		<div xmlns="http://www.w3.org/1999/xhtml">
			{{content}}
		</div>
	</content>
</entry>
endef

#################################### Utils #####################################

define UTILS
define esc
$$(strip $$(subst $$$$,\x24,$$(subst ~,\x7e,$$(subst ",\x22,$$(subst ',\x27,\
   $$1)))))
endef
define slugify
sort $$1 | iconv -c -t ascii//TRANSLIT | sed -E 's/[~^]+//g' | sed -E \
's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+|-+$$$$//g' | tr A-Z a-z | uniq
endef
# render a list of pages based on:
# 1. metadatas file
# 2. view file
# 3. destination file
# 4. date format
# 5. sort flags
define pages
cat $$1 | sort $$5 -t'\t' | while read -r p; do \
	title=`echo "$$$$p" | cut -f1`; \
	timestamp=`echo "$$$$p" | cut -f2`; \
	description=`echo "$$$$p" | cut -f3`; \
	path=`echo "$$$$p" | cut -f4`; \
	breadcrumbs=`echo "$$$$p" | cut -f5`; \
	cover=`echo "$$$$p" | cut -f6`; \
	date=`date +'$$4' -d @$$$$timestamp`; \
	sed $$2 \
	-e "s~{{cover}}~$$$$cover~" \
	-e "s~{{title}}~$$$$title~" \
	-e "s~{{date}}~$$$$date~" \
	-e "s~{{description}}~$$$$description~" \
	-e "s~{{baseurl}}~$$(baseurl)~" \
	-e "s~{{path}}~$$(basepath)$$$$path~" \
	-e "s~{{id}}~$$(baseurl)$$(basepath)$$$$path~" \
	-e "s~{{authorname}}~$$(authorname)~" \
	-e "s~{{authoremail}}~$$(authoremail)~" \
	-e "s~{{breadcrumbs}}~$$$$breadcrumbs~" \
	-e "/{{content}}/{r $$(ROOT)/build/pages/$$$$path/content.html" -e 'd}'\
	>> $$3; \
done
endef
# generate a feed based on:
# 1. the directory of the feed
# 2. the page entries file
# 3. the destination file
# 4. the title of the feed
define atomfeed
sed $$(ROOT)/build/templates/layout/feed.atom \
-e 's~{{title}}~$$4~' \
-e 's~{{id}}~$$(baseurl)$$(basepath)$$1~' \
-e 's~{{sitename}}~$$(sitename)~' \
-e 's~{{link}}~$$(baseurl)$$(basepath)$$1feed.atom~' \
-e 's~{{root}}~$$(baseurl)$$(basepath)~' \
-e 's~{{date}}~$$(DATE)~' \
-e 's~{{sitename}}~$$(sitename)~' \
-e '/{{pages}}/{r $$2' -e 'd}' \
> $$3
endef
endef

################################ Main Makefile #################################

export DATE     = $(shell date --iso-8601=seconds)

PAGE_LIST      := $(shell find pages -mindepth 1 -type d \! -name assets)
PAGE_TAGS_LIST := $(shell find pages -mindepth 1 -type f -name tags)
PAGE_CONF_LIST := $(shell find pages -mindepth 1 -type f -name config)
TPL_LIST       := $(shell find templates -mindepth 1 -type f -name '*.html')
BUILD_TAGS_LIST:= $(patsubst %,build/%page,$(PAGE_TAGS_LIST))
BUILD_MK_LIST  := $(patsubst %,build/%/Makefile,$(PAGE_LIST))
PUBDIR         := public$(basepath)
PUBLIC_PAGES   := $(patsubst pages/%,$(PUBDIR)%,$(PAGE_LIST))
PUBLIC_INDEXES := $(patsubst %,%/index.html,$(PUBLIC_PAGES)) $(PUBDIR)index.html

ASSETS_DIR := $(shell find pages -mindepth 1 -type d -name assets)
JS     := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.js))
CSS    := $(foreach d,$(ASSETS_DIR),$(wildcard $(d)/*.css))
PUBLIC_JS  := $(JS:pages/%=$(PUBDIR)%)
PUBLIC_CSS := $(CSS:pages/%=$(PUBDIR)%)

IMG        := $(shell find pages | grep -E '($(imagesext))$$')
PUBLIC_IMG := $(IMG:pages/%=$(PUBDIR)%)

ASSETS := $(PUBLIC_JS) $(PUBLIC_CSS) $(PUBLIC_IMG)

TEMPLATES := layout/page layout/tag view/full view/tag
TEMPLATES := $(TEMPLATES:%=templates/%.html)
BUILD_TPL := $(patsubst %,build/%,$(sort $(TEMPLATES) $(TPL_LIST)))
ATOM_TPL  := $(patsubst %,build/templates/%.atom,layout/feed view/entry)
TAGS_VIEW   := build/templates/view/$(view).html
TAGS_LAYOUT := build/templates/layout/tag.html

# theses are the variables that will be replaced by the content of a file.
R_VARS     = head breadcrumbs tags content pages
R_VARS_EXP = $(patsubst %,-e 's/\({{%}}\)/\n\1\n/',$(R_VARS))

ifneq ($(strip $(PAGE_TAGS_LIST)),)
TAGS := $(shell $(call slugify,$(PAGE_TAGS_LIST)))
TAGS_META    := $(TAGS:%=build/tags/%/metadatas)
TAGS_INDEXES := $(TAGS:%=$(PUBDIR)tags/%/index.html)
TAGS_FEEDS   := $(TAGS:%=$(PUBDIR)tags/%/feed.atom)
endif

PAGE_FEED_LIST := $(shell grep -rlE 'feed ?= ?1' pages --include config)
PAGE_FEEDS     := $(PAGE_FEED_LIST:pages/%/config=$(PUBDIR)%/feed.atom)

.PHONY: site
site: pages $(ASSETS) $(TAGS_INDEXES) $(TAGS_FEEDS) $(PAGE_FEEDS)\
      $(PUBLIC_INDEXES)

pages:
	$(l0)mkdir $@
	$(l2)#CREA $@ directory

$(ASSETS): $(PUBDIR)%: pages/%
	$(l0)mkdir -p $(@D)
	$(l0)cp $< $@
	$(l2)#PUB $@

$(PUBLIC_INDEXES) $(PAGE_FEEDS): $(PUBDIR)%: build/pages/%
	$(l0)mkdir -p $(@D)
	$(l0)cp $< $@
	$(l2)#PUB $@

$(TAGS_INDEXES): $(PUBDIR)tags/%/index.html: build/tags/%/pages.html \
					   build/pages/head.html \
					   $(TAGS_LAYOUT)
	$(l0)mkdir -p $(@D)
	$(l0)sed $(TAGS_LAYOUT) \
	-e 's~{{sitename}}~$(sitename)~' \
	-e 's~{{tag}}~$*~' \
	-e '/{{head}}/{r build/pages/head.html' -e 'd}' \
	-e '/{{pages}}/{r $<' -e 'd}' \
	> $@
	$(l2)#PUB $@

$(TAGS_FEEDS): $(PUBDIR)%: build/%
	$(l0)mkdir -p $(@D)
	$(l0)cp $< $@
	$(l2)#PUB $@

build/pages/%: build/pages ;

.PHONY: build/pages
build/pages: build/pages/Makefile $(BUILD_MK_LIST) $(BUILD_TPL) $(ATOM_TPL) \
	     build/utils.mk
	$(l0)$(MAKE) -C $@

build/pages/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/Makefile: pages Makefile
	$(l0)mkdir -p $(@D)
	$(l0)echo "$$CONTENT" > $@
	$(l1)#GEN $@

build/pages/%/Makefile: export CONTENT=$(SUB_MAKEFILE)
build/pages/%/Makefile: pages/% Makefile
	$(l0)mkdir -p $(@D)
	$(l0)echo "$$CONTENT" > $@
	$(l1)#GEN $@

build/tags/%/pages.html: $(TAGS_VIEW) build/tags/%/metadatas
	$(l0)mkdir -p $(@D)
	$(l0)echo '<ul>' > $@
	$(l0)$(call pages,build/tags/$*/metadatas,$<,$@,$(dateformat),-nrk2)
	$(l0)echo '</ul>' >> $@
	$(l1)#GEN $@

$(TAGS_META): build/tags ;

.PHONY: build/tags
build/tags: $(BUILD_TAGS_LIST) | build/pages
ifneq ($(strip $(BUILD_TAGS_LIST)),)
	$(l0)mkdir -p $@
	$(l0)cat $(BUILD_TAGS_LIST) > $@/metadatas
	$(l0)for t in `cut -f1 $@/metadatas | sort | uniq`; do \
		mkdir -p $@/$$t; \
		sed -n "s~^$$t\t\(.*\)~\1~p" $@/metadatas \
		> $@/$$t/metadatas.new; \
		cmp --silent $@/$$t/metadatas $@/$$t/metadatas.new \
		|| cp $@/$$t/metadatas.new $@/$$t/metadatas; \
	done
endif

$(BUILD_TAGS_LIST): $(PAGE_TAGS_LIST) $(PAGE_CONF_LIST) | build/pages ;

build/tags/%/feed.atom: build/tags/%/pages.atom build/templates/layout/feed.atom
	$(l0)$(call atomfeed,tags/$*/,$<,$@,Tag: $*)
	$(l1)#GEN $@

.PRECIOUS: build/tags/%/pages.atom
build/tags/%/pages.atom: build/templates/view/entry.atom build/tags/%/metadatas\
			 config
	$(l0)echo > $@
	$(l0)$(call pages,build/tags/$*/metadatas,$<,$@,%FT%T%:z,-nrk2)
	$(l1)#GEN $@

# sanitize templates to avoid problems later: 
$(BUILD_TPL): build/%: %
	$(l0)mkdir -p $(@D)
	$(l0)sed $< $(R_VARS_EXP) > $@
	$(l1)#SAN $@

templates/layout/page.html: export CONTENT=$(PAGE_LAYOUT)
templates/layout/tag.html: export CONTENT=$(TAG_LAYOUT)
templates/view/full.html: export CONTENT=$(FULL_VIEW)
templates/view/tag.html: export CONTENT=$(TAG_VIEW)
build/templates/layout/feed.atom: export CONTENT=$(ATOM_LAYOUT)
build/templates/view/entry.atom: export CONTENT=$(ATOMENTRY_VIEW)
build/utils.mk: export CONTENT=$(UTILS)
$(TEMPLATES) $(ATOM_TPL) build/utils.mk: Makefile
	$(l0)mkdir -p $(@D)
	$(l0)echo "$$CONTENT" > $@
	$(l1)#GEN $@

config:
	$(l0)touch $@
	$(l2)#CREA $@

.PHONY: clean
clean: siteclean buildclean templatesclean

.PHONY: buildclean
buildclean:
	$(l0)rm -rf build
	$(l2)#RMV build files

.PHONY: templatesclean
templatesclean:
	$(l0)rm -rf $(TEMPLATES)
	$(l2)#RMV template files

.PHONY: siteclean
siteclean:
	$(l0)rm -rf public
	$(l2)#RMV public files

.PHONY: run
run:
	$(l0)$(MAKE) test watch -j2

.PHONY: watch
watch:
ifeq (, $(shell which fswatch))
	#ERR could not find fswatch
else
	$(l2)#RUN files watcher
	$(l0)while true; do \
		$(MAKE) site; \
		fswatch -1r --event 30 -Ee "$(watchexclude)" \
			pages templates config Makefile \
			$(if $(strip $(l1)),,#)> /dev/null; \
	done
endif

.PHONY: test
test:
ifeq (, $(shell which busybox))
	#ERR could not find busybox
else
	$(l2)#RUN test server, visit http://localhost:$(testport)$(basepath)
	$(l0)busybox httpd -f -h public -p $(testport)
endif

.PHONY: dev
dev: .gitignore .vscode/settings.json
	echo loglevel = trace >> config

.vscode/settings.json:
	mkdir -p $(@D)
	echo '{"editor.rulers": [{ "column": 80 }],"editor.tabSize": 8}' > $@

.gitignore:
	echo '*' >> $@
	echo '!Makefile' >> $@

.FORCE:
