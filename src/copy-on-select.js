"use strict";

var CopyOnSelect = {

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

    // copy selection on input element
    else if ( (this.in_input_elements) &&
              (t === document.activeElement) &&
              (typeof t.value          === "string") &&
              (typeof t.selectionStart === "number") &&
              (typeof t.selectionEnd   === "number") &&
              (t.selectionStart < t.selectionEnd) )
      this.copy( t.value.substring( t.selectionStart, t.selectionEnd ) );
  },

  async initialize()
  {
    // initialize options from storage ...
    let o = await browser.storage.local.get();
    this.in_input_elements = o.in_input_elements;

    // ... and stay up-to-date on storage changes
    browser.storage.onChanged.addListener(
      ( c ) => {
        if ( "in_input_elements" in c )
          this.in_input_elements = c.in_input_elements.newValue;
      }
    );

    // add event handler on a target as close as possible to the
    // contents
    let t = document.body || document || window;
    t.addEventListener( "mouseup", this, false );
  }

};

CopyOnSelect.initialize();
