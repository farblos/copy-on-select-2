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
raise a mouse button, the current selection, if any, is copied to
the clipboard.  This works in many cases, but [not
always](#restrictions).

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

  Disabled input elements of a web page

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

## Known Issues

Version 2.6

- Option "Copy-on-select in input elements" is not effective on
  chromium-based browsers.  In the sense that on these you cannot
  *disable* copy-on-select in input elements.

  The same is true for non-standard input fields on all browsers,
  see ["pontoon.mozilla.org" input form problem][issue_12].

[issue_12]: https://github.com/farblos/copy-on-select-2/issues/12

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

Version 2.7

**Add-On Changes**

- Provides an onboarding page for add-on installations

- Defines a minimum supported browser version

- Uses new add-on icons

**Infrastructure Changes**:

- Migrates from GitHub to SourceHut as project home.  Adds a
  low-dependency, fully automated release process for the
  SourceHut build service, replacing the previous GitHub-based
  release process.

- Adds an onboarding and test pages served by SourceHut pages

- Uses appropriate licenses according to the Reuse standard

- Better describes restrictions and permissions in the readme

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
