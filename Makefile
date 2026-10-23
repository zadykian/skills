# The gates of `make lint`, the one gate, which the maintainer runs before a push. Any finding
# fails a gate, warnings included; make -k lint runs every gate past a failure. Each gate is a
# target of its own, and those that check files take FILES, every file of their kind when it is
# empty: make vale FILES=README.md.
FILES =

.PHONY: lint shell sizecheck

lint: shell sizecheck

# The shell scripts, tools/ and hooks/ included, through ShellCheck and shfmt.
shell:
	@set -ef; files=$$(tools/files sh $(FILES)); [ -z "$$files" ] || { \
		tools/run shellcheck $$files && tools/run shfmt -d -i 4 $$files; }

# The size caps: 300 lines a file, and 150 the README.
sizecheck:
	tools/sizecheck $(FILES)
