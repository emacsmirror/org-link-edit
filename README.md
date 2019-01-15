Org Link Edit provides Paredit-inspired slurping and barfing commands
for Org link descriptions.

The commentary in [org-link-edit.el][el] contains more details.
org-link-edit.el is available in Org's contrib directory.  See the Org
manual's [installation instructions][install] for information on using
contributed packages.

[el]: https://git.sr.ht/~kyleam/org-link-edit/tree/master/org-link-edit.el#L24
[install]: http://orgmode.org/org.html#Installation

### Contributing

Please send bug reports, feature requests, and other questions to
[~kyleam/public-inbox@lists.sr.ht][lst] with **[org-link-edit]** as
the subject prefix.  You can browse previous Org Link Edit discussions
at <https://lists.sr.ht/~kyleam/public-inbox?search=org-link-edit>.

If you'd like to contribute a patch, thank you!  To keep open the
possibility of including org-link-edit.el into Org proper or ELPA,
contributors are required to [assign copyright][cpy] to the Free
Software Foundation for [most changes][tny] .

Please send patches to the same address listed above.  You can
generate the patch with

    git format-patch --subject-prefix="PATCH org-link-edit" ...

To avoid passing `--subject-prefix` each time you call `format-patch`,
you can configure the repository's default prefix:

    git config format.subjectPrefix "PATCH org-link-edit"

For more information on sending patches, visit
<https://man.sr.ht/git.sr.ht/send-email.md>.

[lst]: mailto:~kyleam/public-inbox@lists.sr.ht
[cpy]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Copyright-Assignment.html
[tny]: https://orgmode.org/worg/org-contribute.html#org2cf82ab
