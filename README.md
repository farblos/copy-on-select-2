<!-- README.md - copy-on-select-2 readme.
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

# Copy on Select 2 - A Productivity Tool Which Copies Selected Text to the Clipboard Automatically

"Are you used to being able to highlight text and have it
instantly copied to the clipboard?  Why not have this
functionality in your browser as well?" -- spyrosoft

This is a fork of
https://addons.mozilla.org/en-US/firefox/addon/copy-on-select by
late
[spyrosoft](https://addons.mozilla.org/en-US/firefox/user/5778000).
See the [version history](#version-history) below for information
on what has changed since the fork.

Up to version 2.4 both add-ons shared a refreshing simplicity (10
lines of code only in the original add-on!).  Starting with
version 2.4, this fork began to grow to cover more use cases.
But still the original principle has not changed: Whenever you
raise the main mouse button, the current selection, if any, is
copied to the clipboard.

This works for [all the different ways to select text in
Firefox](https://support.mozilla.org/kb/mouse-shortcuts-perform-common-tasks#w_selecting-or-editing-text),
but there are some restrictions.  For example, you cannot
copy-on-select on the `mozilla.org` page just referenced in the
previous link.  For more information see [section
Restrictions](#restrictions).

Much more feature-complete, probably even feature-bloated, was
[AutocopySelection2Clipboard](https://addons.mozilla.org/en-US/firefox/addon/autocopyselection2clipboard),
but that disappeared from AMO in early 2022.  Another alternative
is
[AutoCopy](https://addons.mozilla.org/en-US/firefox/addon/autocopy-we).

## Installation

- [Mozilla Firefox][link-amo] ("FF")

  [![Firefox Latest](https://img.shields.io/amo/v/copy-on-select-2)][link-amo]

- Chromium-based browsers (Brave, Ungoogled Chromium) ("cbb")

  Download the latest CRX package from the [release
  page](https://git.sr.ht/~jschmidt/copy-on-select-2/refs)
  (select the link on the version number!) and drag-and-drop it
  onto your browser or open it as a file with `Ctrl+O`.

[link-amo]: https://addons.mozilla.org/en-US/firefox/addon/copy-on-select-2

## Restrictions

Here are some cases where it is difficult or outright impossible
for this add-on to copy-on-select:

- *Technically impossible:*

  Firefox user interface elements outside of the main web page
  (URL bar, dialogues, etc.)

  Special Firefox pages (`about:*`, `view-source:*`), PDF
  documents, XML documents

  Some pages from `mozilla.org` domains

  Disabled input fields of a web page

- *Probably possible, probably not:*

  JavaScript-heavy web pages, in particular if they do funny
  things with the selection (https://docs.google.com)

  Likewise web pages that rely on JavaScript libraries like
  CodeMirror for text input

- *Configurable:*

  Some pages are restricted by [optional
  permissions](#required-and-optional-permissions), which you can
  grant in the add-on manager of your browser

Please consider opening an issue on the [support
site](https://github.com/farblos/copy-on-select-2/issues) or send
a mail to the support email, available on the [Firefox Add-On
Listing][link-amo], if you experience a web page where this
add-on does not copy-on-select.

[link-amo]: https://addons.mozilla.org/en-US/firefox/addon/copy-on-select-2

## Required and Optional Permissions

On Mozilla Firefox this add-on requires the following permissions
to work:

- [Access your data for all websites](https://support.mozilla.org/en-US/kb/permission-request-messages-firefox-extensions#w_access-your-data-for-all-websites)

  This permission is required to read your selection ...

- [Input data to the clipboard](https://support.mozilla.org/en-US/kb/permission-request-messages-firefox-extensions#w_input-data-to-the-clipboard)

  ... and this one to automatically put the selection into your
  clipboard.

In addition to the required permissions above, there are some
optional permissions which you can grant in the add-on manager of
your browser to extend the scope of this add-on:

- (FF) "Run in Private Windows", (cbb) "Allow in Incognito"

- (cbb) "Allow access to file URLs"

- (FF) "Run on sites with restrictions"

## Generally Useful Options

<!-- (sync-mark-in-input-elements) -->
### Copy-on-select in input elements

If this option is checked, copy-on-select also processes
selections in input fields, like text boxes or text areas.

The interesting question here is why you would want to switch
that off?  Because in editable input elements you occasionally
might want to mark text not to copy it, but rather to overwrite
it with what is on the clipboard ... and that you just have
overwritten by marking the text you wanted to overwrite.

## Experimental Options

The following options control somewhat special features.  Chances
are that you do not need to worry about these.

<!-- (sync-mark-use-native-copy) -->
### Use native copy command

Browsers provide two alternatives to write to the clipboard, one
more recent, text-only copy method and a native copy command.  If
this option is checked, copy-on-select uses the native copy
command to copy selections to the clipboard, otherwise the
text-only copy method.

The text-only copy method provides more freedom for what text to
place into the clipboard, while the native copy command exactly
copies to the clipboard what `Ctrl+V` (or `Command+V`) would
copy.  In particular, using the native copy command also allows
to copy-on-select rich text including markup information.  While
that might sound promising, there is one drawback: The native
copy command is based on the [deprecated
`execCommand`](https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand).

<!-- (sync-mark-trim-triple-clicks) -->
### Trim triple-click paragraph selections

Triple-clicks in general select the paragraph being clicked on.
At least for Firefox the resulting text selection may include
leading and trailing whitespace.  If this option is checked,
copy-on-select trims such whitespace while copying the selection
to the clipboard.

Cbbs seem to trim such whitespace by default, so on these
browsers this option does not have any effect.

<!-- (sync-mark-multi-range-sep) -->
### Join multi-range selections with

On Firefox you can select multiple text (or other) ranges by
holding down the `Control` key during the selection operation.
For text ranges Firefox builds the resulting overall selection
simply by concatenating the selected ranges, without any
separator in between them.  If the separator string given by this
option (in [percent encoding][percent_encoding]) is non-empty,
copy-on-select uses it as separator between the selected ranges
while copying the selection to the clipboard.  But only if all
selected ranges are actually text ranges.

Use an empty separator string to disable this feature.

Cbbs do not provide multi-range selection, so on these browsers
this option does not have any effect.

[percent_encoding]: https://en.wikipedia.org/wiki/Percent-encoding

## Known Issues

In All Versions

<!-- (sync-mark-use-native-copy) -->
- Copy-on-select does not (and cannot) always properly handle
  multi-range selections, for example, not in input fields.  As a
  work-around you can switch on option "Use native copy command".

Since Version 2.6

<!-- (sync-mark-in-input-elements) -->
- For some non-standard input fields copy-on-select is always
  active, regardless of option "Copy-on-select in input
  elements".  See ["pontoon.mozilla.org" input form
  problem][issue_12].

[issue_12]: https://github.com/farblos/copy-on-select-2/issues/12

Since Version 2.3

- Copy-on-select does not work if you start a selection and
  release the mouse button for that selection outside of the
  browser window.  The same holds if you start a selection in an
  iframe and release the mouse button outside of the iframe.

## Low-Dependency Build Script

(This section is about how this add-on is built, and as a regular
user you can blissfully ignore it.)

I feature a slight paranoia against all these fancy GitHub
actions and other build dependencies, in particular if they
involve processing JWTs or other sensitive data of mine.  And I
actually like the challenge of reinventing wheels with low-level
tools.  There are definitely cons to that approach, but also
pros, given the infamous [left-pad
incident](https://en.wikipedia.org/wiki/Npm_left-pad_incident) or
the even more infamous [XZ Utils
backdoor](https://en.wikipedia.org/wiki/XZ_Utils_backdoor).

For this add-on I developed a single, low-dependency,
self-contained, monolithic Bash build script that covers the
complete add-on build and release cycle: From building the add-on
XPI (and CRX) to uploading it on SourceHut's release page and to
releasing it on addons.mozilla.org.  As an added benefit, most of
the build script runs locally just as well as on the SourceHut
build service, which eases its development and maintenance a lot.

The build script is tailored to this add-on's needs, and not
configurable at all.  However, the build script is hopefully well
structured, well documented, and comes with a permissive
Unlicense, so it should be relatively easy to rip it apart and
assemble the pieces to what other add-ons need.

<!--
  == Keep format and position of the section below as expected by
  == the build script.
  -->

## Version History

Version 2.8

*Add-On Changes*

- Improves event handling to reduce false copy-on-selects.  Which
  is an important prerequisite to implement a reasonable
  indicator for copy-on-selects, as requested in [issue
  #14](https://github.com/farblos/copy-on-select-2/issues/14).

- Adds options for handling some more experimental aspects of
  copy-on-select, most notably the option to use native copy

- Streamlines and generalizes option handling

*Infrastructure Changes*

- Extends test instructions, in general and for the new features
  in particular

Version 2.7

*Add-On Changes*

- Provides an onboarding page for add-on installations

- Defines a minimum supported browser version

- Uses new add-on icons

*Infrastructure Changes*

- Migrates from GitHub to SourceHut as project home.  Adds a
  low-dependency, fully automated release process for the
  SourceHut build service, replacing the previous GitHub-based
  release process.

- Adds an onboarding and test pages served by SourceHut pages

- Uses appropriate licenses according to the Reuse standard

- Better describes add-on restrictions and permissions in the
  readme

Version 2.6

- Implements RFE [Version for chromium web browsers][issue_10].

  Polyfills missing APIs.  Adds release steps to create an MV3,
  CRX3 package (while leaving MV2 for the Firefox XPI).

[issue_10]: https://github.com/farblos/copy-on-select-2/issues/10

Version 2.5

- Fixes issue [Does not work on local web pages in htmlz format][issue_8]:

  Tracks document changes to properly update event handlers.

[issue_8]: https://github.com/farblos/copy-on-select-2/issues/8

Version 2.4

- Implements RFE [Enable copy-on-select for input fields][issue_6].

  Provides an option to control this feature.

- Uses non-deprecated APIs to write to the clipboard.

  Requires an additional permission to implement this ("Input
  data to the clipboard").

[issue_6]: https://github.com/farblos/copy-on-select-2/issues/6

Version 2.3

- Fixes issue [Use more appropriate event sources][issue_4].

  (And still 10 lines of code only!  But they are getting
  longer.)

[issue_4]: https://github.com/farblos/copy-on-select-2/issues/4

Version 2.2

- Supports copy-on-select in iframes.

Version 2.1

- Fixes issue [Dont work at docs.google.com/spreadsheets][issue_1]:

  Ignores all events on pages from `docs.google.com`.

[issue_1]: https://github.com/farblos/copy-on-select-2/issues/1

Version 2.0

- Provides a clone of the original add-on with metadata modified
  to extend its scope also to file-based URLs.
