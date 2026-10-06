#
#  Makefile
#  UMCDesk workspace entry point
#
#  Created by euijjang97 on 10/6/26.
#

.DEFAULT_GOAL := help
TARGETS := help bootstrap check-mise doctor install generate gen generate-open edit edit-project \
    graph cache-warm open build pick test test-pick test-network clean clean-dd reset

.PHONY: $(TARGETS)
$(TARGETS):
	@$(MAKE) --no-print-directory -C UMCDesk $@
