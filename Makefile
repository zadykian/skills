# The gates of `make lint`, the one gate, which the maintainer runs before a push. Any finding
# fails a gate, warnings included; make -k lint runs every gate past a failure. Each gate is a
# target of its own, and those that check files take FILES, every file of their kind when it is
# empty: make vale FILES=README.md.
FILES =

.PHONY: lint shell sizecheck vale lychee rumdl

lint: shell sizecheck vale lychee rumdl

# The shell scripts, tools/ and hooks/ included, through ShellCheck and shfmt.
shell:
	@set -ef; files=$$(tools/files sh $(FILES)); [ -z "$$files" ] || { \
		tools/run shellcheck $$files && tools/run shfmt -d -i 4 $$files; }

# The size caps: 300 lines a file, and 150 the README.
sizecheck:
	tools/sizecheck $(FILES)

# Vale (.vale.ini) on the Markdown files git lists, new ones included.
vale:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || tools/run vale $$files

# Links to files and their headings in the Markdown files.
lychee:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || \
		tools/run lychee --offline --include-fragments --no-progress $$files

# rumdl (.rumdl.toml) on the Markdown files, with no cache, which it would keep in the tree.
rumdl:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || \
		tools/run rumdl check --no-cache $$files
