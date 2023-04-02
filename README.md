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

The strength of both add-ons is their extreme simplicity (10
lines of code only!): Whenever you raise a mouse button, the
current selection, if any, is copied to the clipboard.  As you
might have guessed, that simplicity comes at a cost: This add-on
works reliably only in the most basic scenario, namely when
copying text from a web page.

Much more feature-complete, probably even feature-bloated, is
[AutocopySelection2Clipboard](https://addons.mozilla.org/en-US/firefox/addon/autocopyselection2clipboard),
but that disappeared from AMO in early 2022.  Another alternative
is
[AutoCopy](https://addons.mozilla.org/en-US/firefox/addon/autocopy-we).

## Installation

- [Mozilla Firefox][link-amo]

  [![Firefox Latest](https://img.shields.io/amo/v/copy-on-select-2)][link-amo]

<!--
  == Keep GitHub workflow release.yml in sync with the format of
  == the section below.
  -->

## Version History

Version 2.2.0

- Supports copy-on-select in iframes.

Version 2.1

- Fixes issue [Dont work at docs.google.com/spreadsheets][issue_1]:

  Ignores all events on pages from `docs.google.com`.

[issue_1]: https://github.com/farblos/copy-on-select-2/issues/1

Version 2.0

- Provides a clone of the original add-on with metadata modified
  to extend its scope also to file-based URLs.
