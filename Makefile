
LOAD_PATH ?=
BATCH = emacs -Q --batch $(LOAD_PATH)

all: org-link-edit-autoloads.el org-link-edit.elc

.PHONY: test
test: org-link-edit.elc
	@$(BATCH) -L . -l test-org-link-edit \
	--eval "(ert-run-tests-batch-and-exit '(not (tag interactive)))"

.PHONY: clean
clean:
	$(RM) org-link-edit-autoloads.el org-link-edit.elc

%.elc: %.el
	@$(BATCH) -f batch-byte-compile $<

%-autoloads.el: %.el
	@$(BATCH) --eval \
	"(let ((make-backup-files nil)) \
	   (if (fboundp 'loaddefs-generate) \
	       (loaddefs-generate default-directory \"$@\" \
				  (list \"test-org-link-edit.el\")) \
	     (update-file-autoloads \"$(CURDIR)/$<\" t \"$(CURDIR)/$@\")))"
