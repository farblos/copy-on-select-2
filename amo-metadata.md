<!-- amo-metadata.md - copy-on-select-2 AMO metadata.
  ==
  == Copyright (C) 2022-2024 Jens Schmidt
  ==
  == This Source Code Form is subject to the terms of the Mozilla Public
  == License, v. 2.0. If a copy of the MPL was not distributed with this
  == file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ==
  == SPDX-FileCopyrightText: 2022-2024 Jens Schmidt
  ==
  == SPDX-License-Identifier: MPL-2.0 -->

# Format Information

This file provides all the necessary AMO metadata for the
copy-on-select-2 add-on.  The metadata should follow after this
section as a sequence of more level one sections having the
following structure:

    # Non-Description Metadata

        {
          <non-description JSON metadata>
        }

    # Description en-US

    <markdown description for language en-US>

    # Description <language-code-01>

    <markdown description for language 01>

    ...

The non-description JSON metadata can refer to jq variable
`$desc_en_US` to include the add-on description for language
`en-US`, etc.

# Non-Description Metadata

    {
      "categories":      [ "other" ],
      "description":     { "en-US": $desc_en_US },
      "homepage":        { "en-US": "https://sr.ht/~jschmidt/copy-on-select-2" },
      "is_disabled":     false,
      "is_experimental": false,
      "name":            { "en-US": "Copy On Select 2" },
      "slug":            "copy-on-select-2",
      "summary":         { "en-US": "A productivity tool which copies selected text to the clipboard automatically" },
      "support_email":   { "en-US": "~jschmidt/copy-on-select-2@lists.sr.ht" },
      "tags":            []
    }

# Description en-US

"Are you used to being able to highlight text and have it
instantly copied to the clipboard?  Why not have this
functionality in your browser as well?" -- spyrosoft

This is a fork of
https://addons.mozilla.org/en-US/firefox/addon/copy-on-select by
late
[spyrosoft](https://addons.mozilla.org/en-US/firefox/user/5778000).
See the [version
history](https://git.sr.ht/~jschmidt/copy-on-select-2#version-history)
on SourceHut for information on what has changed since the fork.

Here are some cases where it is difficult or outright impossible
for this add-on to copy-on-select:

- *Technically impossible:*

  Firefox user interface elements outside of the main web page
  (URL bar, dialogues, etc.)

  Special Firefox pages (`about:*`, `view-source:*`), PDF
  documents, XML documents

  Disabled input elements of a web page

- *Probably possible, probably not:*

  JavaScript-heavy web pages, in particular if they do funny
  things with the selection (https://docs.google.com)

  Likewise web pages that rely on JavaScript libraries like
  CodeMirror for text input

Please consider opening an issue on the [support
site](https://github.com/farblos/copy-on-select-2/issues) or send
a mail to the support email if you experience a web page where
this add-on does not copy-on-select.
