PROJECT = logsc

ERLC_OPTS ?= -Werror +debug_info +warn_export_vars \
	+warn_shadow_vars +warn_obsolete_guard +{parse_transform,lager_transform}

DEPS = lager

include erlang.mk

shell-app: build-shell-deps app
	$(gen_verbose) erl $(SHELL_PATH) $(SHELL_OPTS) -s logsc -config logsc
