.PHONY: all backup test diff download ob_changes.patch init eclipse web init-web html

all:
	@echo "Sample make file for experimentation.  Still needs work.  Only backup implemented"

backup:
	rsync -av --exclude=".*" --exclude="openbabel/" --delete . ../../Box\ Sync/Projects/GitBackups/mofid

# Make this generic later on...
bin/sbu: src/sbu.cpp openbabel/build/lib/cifformat.so
	cd bin && make sbu
bin/sobgrep: src/sobgrep.cpp openbabel/build/lib/cifformat.so
	cd bin && make sobgrep
bin/searchdb: src/searchdb.cpp openbabel/build/lib/cifformat.so
	cd bin && make searchdb
bin/tsfm_smiles: src/tsfm_smiles.cpp openbabel/build/lib/cifformat.so
	cd bin && make tsfm_smiles

# Be careful: multi-line, nonescaped commands in Make run in separate shells
# Generic rules for compiling relevant (modified by me) formats
openbabel/build/lib/cifformat.so: openbabel/src/formats/cifformat.cpp openbabel/src/mol.cpp
	cd openbabel/build; \
	make cifformat; \
	make install/fast

diff: ob_changes.patch

ob_changes.patch:
	git diff --no-prefix 7810ca7bb1beef14b2a62cf5bad3a8551b187824 -- openbabel/*.cpp openbabel/*.h ':!openbabel/data/*' ':!openbabel/test/*' > $@
	# Lists my changes to the main OpenBabel code

test: bin/sbu
	python Python/check_mof_linkers.py

# Download external programs, if not locally installed
download: Resources/External/Systre-1.2.0-beta2.jar Resources/External/jq

Resources/External/Systre-1.2.0-beta2.jar:
	cd Resources/External; \
	wget https://github.com/odf/gavrog/releases/download/v0.6.0-beta2/Systre-1.2.0-beta2.jar


# Download json parser
# Currently no support for OSX within the Makefile, but it should be straightforward to add it:
# See download page at https://stedolan.github.io/jq/download/
Resources/External/jq:
	JQ_BIN="UNKNOWN"; \
	cd Resources/External; \
	if [[ $$(uname -s) == *"NT"* ]]; then JQ_BIN="jq-win64.exe"; fi; \
	if [[ $$(uname -s) == *"Linux"* ]]; then JQ_BIN="jq-linux64"; fi; \
	wget "https://github.com/stedolan/jq/releases/download/jq-1.6/$$JQ_BIN"; \
	wget "https://raw.githubusercontent.com/stedolan/jq/master/sig/v1.6/sha256sum.txt"; \
	mv sha256sum.txt jq_sha256sum.txt; \
	echo "Verifying checksum integrity of jq executable:"; \
	grep $$JQ_BIN jq_sha256sum.txt | sha256sum --check || exit 55; \
	cp $$JQ_BIN jq; \
	chmod +x jq


init:
	cd openbabel; \
	mkdir build installed; \
	cd build; \
	cmake -DCMAKE_INSTALL_PREFIX=../installed -DBUILD_GUI=OFF ..; \
	make -j2 || exit 2; \
	make install; \
	cd ../../; \
	mkdir Test/; \
	mkdir bin; \
	cd bin; \
	cmake -DOpenBabel2_DIR=../openbabel/build ../src/; \
	make ;\
	cp ../openbabel/build/bin/*.dll .
	# Sets up all the cmake details, so that usage is as simple as
	# `bin/sbu MOF.cif` and re-compilation is as easy as `make bin/sbu`
	# FIXME: the last `cp` hacks together a DLL dependency until I can figure out the cmake command

eclipse:
	cd bin; \
	cmake -G "Eclipse CDT4 - Unix Makefiles" ../src; \

# Emscripten web content below
# In my current Windows setup, these must all be run within Git Bash
# Not yet tested cross-platform in Linux
# Warning: the path to web-data/core.smi has not yet been tested!
init-web:
	source Scripts/import_emscripten.sh; \
	cd openbabel; \
	mkdir embuild eminstall; \
	cd embuild; \
	emcmake cmake .. -DCMAKE_INSTALL_PREFIX=../eminstall/ -DENABLE_TESTS=OFF -DBUILD_SHARED=OFF; \
	cd ../..; \
	mkdir embin; \
	cd embin; \
	emcmake cmake -DOpenBabel2_DIR=../openbabel/embuild -static ../src/ -DCMAKE_CXX_FLAGS="-s EXPORTED_FUNCTIONS=\"['_analyzeMOFc', '_runSearchc', '_SmilesToSVG']\" --preload-file ../openbabel/data@/ob_datadir/ --preload-file ../src/Web/web_data@/web_data/ --pre-js ../src/pre_emscripten.js -s TOTAL_MEMORY=128MB"; \
	mkdir kekule; \
	cd kekule; \
	unzip ../../Resources/kekule.release.0.7.5.170624.zip

openbabel/embuild/obabel.js:
	source Scripts/import_emscripten.sh; \
	cd openbabel/embuild; \
	emmake make; \
	emmake make install

web: embin/sbu.js html

html: src/Web/*.html
	cp $^ embin/

embin/sbu.js: src/sbu.cpp openbabel/embuild/obabel.js src/pre_emscripten.js
	source Scripts/import_emscripten.sh; \
	cd embin; \
	emmake make

