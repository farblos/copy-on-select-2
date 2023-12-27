[link-amo]: https://addons.mozilla.org/en-US/firefox/addon/copy-on-select-2

# Copy on Select 2 - A Productivity Tool Which Copies Selected Text to the Clipboard Automatically

Are you used to being able to highlight text and have it
instantly copied to the clipboard?  Why not have this
functionality in your browser as well?

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
the clipboard.

This works in many cases, but not always.  Here are some cases
which are difficult or outright impossible to handle for this
add-on:

- Technically impossible:

  Firefox user interface elements outside of the main web page
  (URL bar, dialogues, etc.)

  Special Firefox pages (`about:*`, `view-source:*`), XML
  documents

  Disabled input elements of a web page

- Probably possible, probably not:

  JavaScript-heavy web pages, in particular if they do funny
  things with the selection (https://docs.google.com)

Please consider opening an issue on the [support
site](https://github.com/farblos/copy-on-select-2/issues) if you
experience a web page where this add-on does not copy-on-select.

Much more feature-complete, probably even feature-bloated, is
[AutocopySelection2Clipboard](https://addons.mozilla.org/en-US/firefox/addon/autocopyselection2clipboard),
but that disappeared from AMO in early 2022.  Another alternative
is
[AutoCopy](https://addons.mozilla.org/en-US/firefox/addon/autocopy-we).

## Installation

- [Mozilla Firefox][link-amo]

  [![Firefox Latest](https://img.shields.io/amo/v/copy-on-select-2)][link-amo]

- Chromium-based browsers (Brave, Ungoogled Chromium)

  Download the latest CRX package from the [release
  page](https://github.com/farblos/copy-on-select-2/releases) and
  drag-and-drop it onto your browser or open it as a file with
  `Ctrl+O`.

## Known Issues

Version 2.6

- Option "Copy-on-select in input elements" is not effective on
  chromium-based browsers.  In the sense that on these you cannot
  *disable* copy-on-select in input elements.

  The same is true for non-standard input fields on all browsers,
  see ["pontoon.mozilla.org" input form problem][issue_12].

[issue_12]: https://github.com/farblos/copy-on-select-2/issues/12

<!--
  == Keep GitHub workflow release.yml in sync with the format of
  == the section below.
  -->

## Version History

Version 2.6

- Implements RFE [Version for chromium web browsers][issue_10].

  Polyfills missing APIs.  Adds release steps to create an MV3,
  CRX3 package (while leaving MV2 for the Firefox XPI).

[issue_10]: https://github.com/farblos/copy-on-select-2/issues/10

Version 2.5

- Fixes issue [Does not work on local web pages in htmlz format][issue_8].

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
