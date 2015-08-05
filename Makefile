#!/usr/bin/make
#
# Prerequisites:
#
# Mandatory:
#
# kramdown: http://kramdown.rubyforge.org/
#    $ sudo gem install kramdown
#
# Optional:
#
# graphviz:	http://www.graphviz.org/
#    http://www.graphviz.org/Download_macos.php
#    or $ sudo port install graphviz +no_x11
# pdflatex: https://www.tug.org/texlive/
#    follow https://code.google.com/p/mactlmgr/

# some commands:
RM=rm
DOT=dot
KRAMDOWN=kramdown
PDFLATEX=pdflatex

BUILD_DST	:= build

# graphviz
$(BUILD_DST)/%.png: %.dot
	$(DOT) -Tpng -o $@ $<
$(BUILD_DST)/%.pdf: %.dot
	$(DOT) -Tpdf -o $@ $<
$(BUILD_DST)/%.svg: %.dot
	$(DOT) -Tsvg -o $@ $<
$(BUILD_DST)/%.svg: %.svg
	cp $< $@

# markdown / kramdown
$(BUILD_DST)/%.html: %.md
	-$(KRAMDOWN) --template templates/document-mathjax $< > $@
$(BUILD_DST)/%.tex: %.md
	-$(KRAMDOWN) --template templates/document-toc --output latex $< > $@
%.pdf: %.tex
# needs texlive package ucs
# call 2x to get toc right
	-$(PDFLATEX) -output-directory=$(BUILD_DST) $< ; $(PDFLATEX) -output-directory=$(BUILD_DST) $<

.PHONY: clean

SPECS_DOT	:= $(patsubst %.dot,$(BUILD_DST)/%.pdf,$(wildcard **.dot))
SPECS_HTML := $(patsubst %.md,$(BUILD_DST)/%.html,$(wildcard **.md))
SPECS_SVG := $(patsubst %.svg,$(BUILD_DST)/%.svg,$(wildcard **.svg))
SPECS_TEX := $(patsubst %.md,$(BUILD_DST)/%.pdf,$(wildcard **.md))

TARGETS :=  $(SPECS_HTML) $(SPECS_DOT) $(SPECS_SVG)

all:	$(TARGETS)

pdf:	$(SPECS_TEX) $(SPECS_DOT)

clean:
	-$(RM) $(TARGETS) $(SPECS_TEX) *.aux *.log *.out *.toc
