// copy-on-select.js - copy-on-select-2 content script.
//
// Copyright (C) 2022-2024 Jens Schmidt
// Copyright (C) 2016 Bennett Roesch
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// This Source Code Form is “Incompatible With Secondary Licenses”, as
// defined by the Mozilla Public License, v. 2.0.
//
// SPDX-FileCopyrightText: 2022-2024 Jens Schmidt
// SPDX-FileCopyrightText: 2016 Bennett Roesch
//
// SPDX-License-Identifier: MPL-2.0-no-copyleft-exception

"use strict";

// polyfill the "browser" global for chromium compatibility
if ( (typeof globalThis.browser === "undefined") &&
     (typeof globalThis.chrome  !== "undefined") )
  globalThis.browser = chrome;

let CopyOnSelect = {

  // options
  in_input_elements: false,

  async copy( s )
  {
    try {
      // carefully try the modern approach to write to the
      // clipboard ...
      await navigator.clipboard.writeText( s );
    }
    catch ( e ) {
      // ... but fall back to deprecated document.execCommand if
      // that fails, hoping it will pick the right selection.
      // This fall-back is required at least for http pages.
      document.execCommand( "copy" );
    }
  },

  handleEvent( e )
  {
    // ignore synthetic events
    if ( ! e.isTrusted )
      return;

    // ignore events too crooked to be handled by a normal event
    // handler
    if ( e.defaultPrevented )
      return;

    // ignore events on some sites
    if ( (new URL( document.URL )).hostname === "docs.google.com" )
      return;

    let s = document.getSelection().toString();
    let t = e.target;

    // alignment no-op
    if ( false )
      ;

    // copy selection on web page.  Do not try to optimize that
    // in terms of selection.type === "Range", as that may result
    // in false positives that nix out the clipboard, then.
    else if ( (s.length > 0) )
      this.copy( s );

    // copy selection on input element.  Chromium-based browsers
    // do not handle selections in input elements differently
    // from regular selections.  Accordingly, on these browsers
    // we do not reach this branch when text from an input
    // element is selected, and user option "in_input_elements"
    // is not effective.
    else if ( (this.in_input_elements) &&
              (t === document.activeElement) &&
              (typeof t.value          === "string") &&
              (typeof t.selectionStart === "number") &&
              (typeof t.selectionEnd   === "number") &&
              (t.selectionStart < t.selectionEnd) )
      this.copy( t.value.substring( t.selectionStart, t.selectionEnd ) );
  },

  // sets up a capturing event handler on the window
  setupCapturing() {
    window.addEventListener( "mouseup", this, true );
  },

  target: null,

  observer: null,

  // sets up a bubbling event handler on some element as close to
  // the document contents as possible.  Uses an observer to keep
  // track of changes in the document and its element.
  setupBubbling() {
    try {
      this.target.removeEventListener( "mouseup", this, false );
    }
    catch {}
    this.target = document.body ||
                  document.documentElement ||
                  document ||
                  window;
    this.target.addEventListener( "mouseup", this, false );

    try {
      this.observer.disconnect();
    }
    catch {}
    this.observer.observe( document, { childList: true } );
    if ( document.documentElement )
      this.observer.observe( document.documentElement, { childList: true } );
  },

  async initialize()
  {
    // initialize options from storage ...
    let os = await browser.storage.local.get();
    this.in_input_elements = os.in_input_elements;

    // ... and stay up-to-date on storage changes
    browser.storage.onChanged.addListener(
      ( c ) => {
        if ( "in_input_elements" in c )
          this.in_input_elements = c.in_input_elements.newValue;
      }
    );

    // set up a bubbling event handler and an observer, using the
    // setup function also as (bound) observer function.
    //
    // We have considered using a capturing event handler but
    // decided against it since:
    //
    // - the current bubbling model seems to work fine and
    //
    // - it may have benefits to be the last one to see the
    //   selection - maybe something else has been set up to
    //   modify it to the user's needs.
    //
    // However, using a capturing event handler results in much
    // simpler code (see the otherwise unused function
    // setupCapturing).  And according to this [1] discussion no
    // problems are to be expected by using the capturing model.
    // Probably we switch when there is some critical user mass
    // that is willing to file issues on GitHub.
    //
    // 1: https://discourse.mozilla.org/t/121436
    this.observer = new MutationObserver( this.setupBubbling.bind( this ) );
    this.setupBubbling();
  }

};

CopyOnSelect.initialize();
