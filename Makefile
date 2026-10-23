# The gates of `make lint`, the one gate, which CI's lint job runs, and the maintainer before a
# push. Any finding fails a gate, warnings included; make -k lint runs every gate past a failure.
# Each gate is a target of its own, and those that check files take FILES, every file of their kind
# when it is empty: make vale FILES=README.md.
FILES =
# The ref after which tools/commits checks the commits' messages, up to HEAD.
BASE = origin/main
# The commits gitleaks scans, as git log's options, which its --log-opts takes: every commit of
# the history when empty.
LOG_OPTS =
# The claude that validates the marketplace and the skills. CI's is the one .github/claude pins.
CLAUDE = claude

.PHONY: lint shell sizecheck vale lychee rumdl actionlint zizmor gitleaks commits hooks plugins

lint: shell sizecheck vale lychee rumdl actionlint zizmor gitleaks commits hooks plugins

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

# The workflows' shell scripts go through the pinned ShellCheck.
actionlint:
	shellcheck="$$(tools/run -path shellcheck)" && \
		tools/run actionlint -shellcheck="$$shellcheck" -pyflakes=

# The workflows, with the online audits where GH_TOKEN is set, as in CI.
zizmor:
	tools/run zizmor .

# The commits of LOG_OPTS. --redact keeps a secret it finds out of the log, which is public.
gitleaks:
	tools/run gitleaks git --no-banner --redact --verbose \
		$(if $(LOG_OPTS),--log-opts='$(LOG_OPTS)') .

# The headers and bodies of the commits from BASE to HEAD.
commits:
	tools/commits $(BASE)

# The lint plugin's hooks, against throwaway repositories.
hooks:
	tools/hookcheck

# claude's own checks, its warnings counted as errors: of the marketplace, and of the skills. A
# check of the marketplace opens no skill of a bundle sourced from ./, so a copy of skills/ takes
# a check of its own, as a plugin without a manifest.
plugins:
	@set -e; [ ! -f .claude-plugin/marketplace.json ] || $(CLAUDE) plugin validate . --strict; \
		[ -d skills ] || exit 0; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
		mkdir "$$tmp/skills" && cp -R skills README.md LICENSE "$$tmp/skills"; \
		$(CLAUDE) plugin validate "$$tmp/skills" --strict

