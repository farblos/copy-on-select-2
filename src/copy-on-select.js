"use strict";

var CopyOnSelect = {

  // options
  in_input_elements: false,

  async copy( selection )
  {
    try {
      await navigator.clipboard.writeText( selection.toString() );
    }
    catch ( e ) {
      // fall back to deprecated document.execCommand, hoping it
      // will pick the right selection
      document.execCommand( "copy" );
    }
  },

  handleEvent( e )
  {
    // ignore synthetic events
    if ( ! e.isTrusted )
      return;

    // ignore events too crooked to be handled by a normal event
    // handler (as used, for example, on docs.google.com)
    if ( e.defaultPrevented )
      return;

    let t = e.target;

    // alignment no-op
    if ( false )
      ;

    // copy selection on web page
    else if ( (document.getSelection().type === "Range") )
      this.copy( document.getSelection() );

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

    // add event handlers on a target as close as possible
    // to the contents
    let t = document.body || document || window;
    t.addEventListener( "mouseup", this, false );
  }

};

CopyOnSelect.initialize();
