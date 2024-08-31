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

const EMPTY_ARRAY = [];

// The following classes provide an abstraction of the various
// available selection types:
//
// - Selection - base class, used only as factory for one of the
//   possible concrete classes
//
// - NoSelection - an absent or empty selection
//
// - InputElementSelection - a selection in an (active) input
//   element
//
// - PageSelection - a regular selection on a web page
//
// The concrete subclasses provide the following properties and
// methods:
//
// - collapsed (read-only)
//
//   Provides whether this selection is collapsed aka. empty.
//
// - singleRanged (read-only)
//
//   Provides whether this selection consists of exactly one
//   non-collapsed range.
//
// - ranges (read-only)
//
//   Provides the non-collapsed ranges of this selection as an
//   array.  Clients of this method may safely use only method
//   toString() on the returned ranges.
//
// - contains( e )
//
//   Returns false if the specified mouse event definitely did
//   not take place in this selection, otherwise true.
//
// - equals( s )
//
//   Returns whether the specified selection equals this
//   selection.
//
// - toString()
//
//   Converts this selection to a string.
//
// These classes serve the following purposes:
//
// - Detect collapsed and single-ranged selections and filter
//   collapsed ranges from multi-ranged selections.  This
//   requires "short-term", per-handler-call storage of selection
//   information and properties collapsed, singleRanged, and
//   ranges.
//
// - Detect mouseup events in an existing selection.  This
//   requires "long-term" storage and comparison of selection
//   information across handler calls through methods contains
//   and equals.
//
// - Conversion of the current selection or its multiple ranges
//   to a string.  This requires "short-term" storage of
//   selection information and method toString.

class Selection
{
  static noSelection = null;

  // determines the current selection based on the specified
  // document and event and returns it
  static current( d, e )
  {
    const sel = d.getSelection();

    let elt;
    if ( ! sel.isCollapsed )
      return new PageSelection( sel );
    else if ( (elt = e.target) &&
              (elt === d.activeElement) &&
              (typeof elt.value          === "string") &&
              (typeof elt.selectionStart === "number") &&
              (typeof elt.selectionEnd   === "number") )
      return new InputElementSelection( elt );
    else if ( Selection.noSelection )
      return Selection.noSelection;
    else
      return Selection.noSelection = new NoSelection();
  }
}

class NoSelection extends Selection
{
  constructor()
  {
    super();
  }

  get collapsed()
  {
    return true;
  }

  get singleRanged()
  {
    return false;
  }

  get ranges()
  {
    return EMPTY_ARRAY;
  }

  contains( e )
  {
    return false;
  }

  equals( o )
  {
    return (o instanceof NoSelection);
  }

  toString()
  {
    return "";
  }
}

class InputElementSelection extends Selection
{
  _elt   = null;

  _start = null;

  _end   = null;

  _rect  = null;

  constructor( elt )
  {
    super();
    this._elt   = elt;
    this._start = elt.selectionStart;
    this._end   = elt.selectionEnd;
    this._rect  = elt.getBoundingClientRect();
  }

  get collapsed()
  {
    return ! (this._elt.selectionStart < this._elt.selectionEnd);
  }

  get singleRanged()
  {
    return (this._elt.selectionStart < this._elt.selectionEnd);
  }

  get ranges()
  {
    return (this._elt.selectionStart < this._elt.selectionEnd) ?
           [ this ] : EMPTY_ARRAY;
  }

  contains( e )
  {
    const r = this._rect;
    return true &&
      (r.left <= e.clientX) && (e.clientX <= r.right) &&
      (r.top  <= e.clientY) && (e.clientY <= r.bottom);
  }

  equals( o )
  {
    return true &&
      (o instanceof InputElementSelection) &&
      (o._elt   === this._elt) &&
      (o._start === this._start) &&
      (o._end   === this._end);
  }

  toString()
  {
    if ( this._elt.selectionStart < this._elt.selectionEnd )
      return this._elt.value.substring( this._elt.selectionStart,
                                        this._elt.selectionEnd );
    else
      return "";
  }
}

class PageSelection extends Selection
{
  _sel       = null;

  _collapsed = null;

  // long-term storage for cloned ranges
  _ranges    = null;

  // short-term storage of non-collapsed ranges, initialized
  // lazily by method ncranges
  _ncranges  = null;

  constructor( sel )
  {
    super();
    this._sel = sel;
    this._collapsed = sel.isCollapsed;
    this._ranges =
      Array( sel.rangeCount ).fill().
      map( ( _, i ) => (sel.getRangeAt( i ).cloneRange()) );
    this._ncranges = null;
  }

  ncranges()
  {
    if ( this._ncranges )
      return this._ncranges;
    else
      return this._ncranges =
        Array( this._sel.rangeCount ).fill().
        map( ( _, i ) => (this._sel.getRangeAt( i )) ).
        filter( ( r ) => (! r.collapsed) );
  }

  get collapsed()
  {
    return this._sel.collapsed;
  }

  get singleRanged()
  {
    return (this.ncranges().length === 1);
  }

  get ranges()
  {
    return this.ncranges();
  }

  contains( e )
  {
    for ( const r of this._ranges )
      for ( const b of r.getClientRects() )
        if ( (b.left <= e.clientX) && (e.clientX <= b.right) &&
             (b.top  <= e.clientY) && (e.clientY <= b.bottom) )
          return true;
    return false;
  }

  equals( o )
  {
    return true &&
      (o instanceof PageSelection) &&
      (o._collapsed === this._collapsed) &&
      (o._ranges.length === this._ranges.length) &&
      (o._ranges.every( ( or, i ) => {
        const tr = this._ranges[i];
        return true &&
          (or.collapsed      === tr.collapsed) &&
          (or.startContainer === tr.startContainer) &&
          (or.startOffset    === tr.startOffset) &&
          (or.endContainer   === tr.endContainer) &&
          (or.endOffset      === tr.endOffset); } ));
  }

  toString()
  {
    return this._sel.toString();
  }
}

class CopyOnSelect
{
  // Method initialize sets up fields for all of this add-on's
  // options with names equal to the option names.

  // if the most recent event handled by method handleEvent was a
  // single-click mousedown event, this field holds the selection
  // present at the time of that event, otherwise null
  downSelection = null;

  async copy( s )
  {
    // never clear the clipboard by copying an empty string to it
    if ( s.length === 0 )
      return;

    try {
      // carefully try the modern approach to write to the
      // clipboard ...
      await navigator.clipboard.writeText( s );
    }
    catch ( e ) {
      // ... but fall back to deprecated document.execCommand if
      // that fails, hoping it will pick the right selection
      document.execCommand( "copy" );
    }
  }

  handleEvent( e )
  {
    // ignore synthetic events
    if ( ! e.isTrusted )
      return;

    // ignore events too crooked to be handled by a normal event
    // handler
    if ( e.defaultPrevented )
      return;

    // ignore events resulting from anything but the main button,
    // since only that ever may select things
    if ( e.button !== 0 )
      return;

    // ignore events on some sites
    if ( (new URL( document.URL )).hostname === "docs.google.com" )
      return;

    const sel = Selection.current( document, e );

    // we somewhat assume in the following that a non-collapsed
    // selection contains at least one non-collapsed range
    if ( sel.collapsed )
      return;

    if ( (sel instanceof InputElementSelection) &&
         (! this.in_input_elements) )
      return;

    // detect mouseup events in an existing selection.  On FF at
    // least a click into an existing selection collapses the
    // selection only *after* the mouseup event, thus resulting
    // in spurious copy-on-selects.
    //
    // To detect these, take note of the current selection during
    // the mousedown and compare that to the current selection
    // during mouseup.  If they are equal and if the event is
    // somewhat related to the selection, assume the mouseup
    // happened in an existing selection and ignore it.
    //
    // As an extra wrinkle consider the number of clicks: If the
    // mousedown event has happened as part of a multi-click,
    // then ignore it for the purpose of this heuristics.
    // (Property "detail" on mousedown or mouseup events is sort
    // of unspecified, but both FF and cbbs actually provide it.)
    if ( (e.type === "mousedown") &&
         (e.detail === 1) ) {
      this.downSelection = sel;
      return;
    }
    else if ( (e.type === "mousedown") ) {
      this.downSelection = null;
      return;
    }
    if ( (this.downSelection) &&
         (this.downSelection.equals( sel )) &&
         (this.downSelection.contains( e )) ) {
      this.downSelection = null;
      return;
    }
    else
      this.downSelection = null;

    // copy a single-range selection or a multi-range selection
    // with multi-range selection separation switched off.
    //
    // On FF a control-click while some selection is already
    // active creates a multi-range selection of the previously
    // active ranges and a collapsed new range.  Properties
    // "singleRanged" and "ranges" of our selection classes take
    // that into account by filtering collapsed ranges from the
    // active ranges.
    if ( (sel.singleRanged) &&
         (e.detail === 3) &&
         (this.trim_triple_clicks) ) {
      this.copy( sel.toString().trim() );
    }
    else if ( (sel.singleRanged) ) {
      this.copy( sel.toString() );
    }
    else if ( (this.multi_range_sep.length === 0) ) {
      this.copy( sel.toString() );
    }
    // handle text-only multi-range selections
    else if ( sel.ranges.every( ( r ) =>
                ((r.startContainer.nodeType === Node.TEXT_NODE) ||
                 (r.endContainer.nodeType   === Node.TEXT_NODE)) ) ) {
      this.copy( sel.ranges.join( decodeURIComponent( this.multi_range_sep ) ) );
    }
    // handle all other multi-range selections.  Use the
    // selection itself (and not its ranges) as a string source
    // in this case, since that it closer to the browser APIs.
    else {
      this.copy( sel.toString() );
    }
  }

  // sets up a capturing event handler on the window
  setupCapturing() {
    window.addEventListener( "mouseup", this, true );
    window.addEventListener( "mousedown", this, true );
  }

  target = null;

  observer = null;

  // sets up a bubbling event handler on some element as close to
  // the document contents as possible.  Uses an observer to keep
  // track of changes in the document and its element.
  setupBubbling()
  {
    try {
      this.target.removeEventListener( "mouseup", this, false );
      this.target.removeEventListener( "mousedown", this, false );
    }
    catch {}
    this.target = document.body ||
                  document.documentElement ||
                  document ||
                  window;
    this.target.addEventListener( "mouseup", this, false );
    this.target.addEventListener( "mousedown", this, false );

    try {
      this.observer.disconnect();
    }
    catch {}
    this.observer.observe( document, { childList: true } );
    if ( document.documentElement )
      this.observer.observe( document.documentElement, { childList: true } );
  }

  async initialize()
  {
    // initialize option fields from storage ...
    const o = await loadLocalStorage();
    for ( const [ option, value ] of Object.entries( o ) )
      if ( Object.hasOwn( OPTIONS, option ) )
        this[option] = value;
      else
        console.error( `Cannot initialize unknown option field "${option}".` );
    for ( const option of Object.keys( OPTIONS ) )
      if ( ! Object.hasOwn( o, option ) )
        console.error( `Cannot initialize option field from missing option "${option}".` );

    // ... and stay up-to-date on storage changes
    browser.storage.onChanged.addListener( ( c ) => {
      for ( const [ option, { newValue: value } ] of Object.entries( c ) )
        if ( Object.hasOwn( OPTIONS, option ) )
          this[option] = value;
        else
          console.error( `Cannot update unknown option field "${option}".` );
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
    // that is willing to report issues.
    //
    // 1: https://discourse.mozilla.org/t/121436
    this.observer = new MutationObserver( this.setupBubbling.bind( this ) );
    this.setupBubbling();
  }
}

(new CopyOnSelect()).initialize();
