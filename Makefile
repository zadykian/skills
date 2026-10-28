# The gates of `make lint`, the one gate, which CI's lint job runs, and the maintainer before a
# push. Any finding fails a gate, warnings included; make -k lint runs every gate past a failure.
# Each gate is a target of its own, and those that check files take FILES, every file of their kind
# when it is empty: make vale FILES=README.md.
FILES =
# The commits gitleaks scans, as git log's options, which its --log-opts takes: every commit of
# the history when empty.
LOG_OPTS =
# The claude that validates the marketplace and the skills. CI's is the one .github/claude pins.
CLAUDE = claude

.PHONY: lint lint-file lint-tree shell sizecheck vale lychee rumdl actionlint zizmor gitleaks \
	versions hooks plugins test

lint: shell sizecheck vale lychee rumdl actionlint zizmor gitleaks versions hooks plugins

# What the lint plugin's hooks run here: the gates of the file Claude edited, and every gate at
# the end of its turn. An action's metadata and dependabot.yml go through zizmor, as a workflow
# does.
lint-file:
	@$(MAKE) --no-print-directory shell sizecheck vale lychee rumdl FILES='$(FILES)' \
		$(if $(filter .github/workflows/%,$(FILES)),actionlint) \
		$(if $(filter .github/workflows/% .github/dependabot.yml %/action.yml,$(FILES)),zizmor) \
		$(if $(filter skills/% hooks/% .claude-plugin/%,$(FILES)),versions plugins) \
		$(if $(filter hooks/% tools/hookcheck,$(FILES)),hooks)
lint-tree: lint

# The shell scripts, tools/ and hooks/ included, through ShellCheck and shfmt. -x follows each
# source directive into the file it names, as lint-file checks a script without the files it
# sources.
shell:
	@set -ef; files=$$(tools/files sh $(FILES)); [ -z "$$files" ] || { \
		tools/run shellcheck -x $$files && tools/run shfmt -d -i 4 $$files; }

# The size cap: 300 lines a file.
sizecheck:
	tools/sizecheck $(FILES)

# Vale (.vale.ini) on the Markdown files git lists, new ones included.
vale:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || tools/run vale $$files

# Links to files and their headings in the Markdown files.
lychee:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || \
		tools/run lychee --offline --include-fragments --no-progress $$files

# rumdl (.rumdl.toml) on the Markdown files, with no cache, which it would keep in the tree. A
# warning on its config, such as an unknown rule in a file's directive, fails the gate too.
rumdl:
	@set -ef; files=$$(tools/files md $(FILES)); [ -z "$$files" ] || \
		tools/run rumdl check --no-cache --deny-config-warnings $$files

# The workflows' shell scripts go through the pinned ShellCheck.
actionlint:
	shellcheck="$$(tools/run -path shellcheck)" && \
		tools/run actionlint -shellcheck="$$shellcheck" -pyflakes=

# The workflows, the actions' metadata and dependabot.yml, with the online audits where GH_TOKEN
# is set, as in CI.
zizmor:
	tools/run zizmor .

# The commits of LOG_OPTS. --redact keeps a secret it finds out of the log, which is public.
gitleaks:
	tools/run gitleaks git --no-banner --redact --verbose \
		$(if $(LOG_OPTS),--log-opts='$(LOG_OPTS)') .

# The bundles, their skills and hooks, and the version against the last release's tag.
versions:
	tools/versioncheck

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

# The actions' cases, of each tests/NAME.sh, against tests/gh, the fake gh. They need git and jq.
test:
	tests/run
