// common.js - copy-on-select-2 library.
//
// Copyright (C) 2024 Jens Schmidt
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// SPDX-FileCopyrightText: 2024 Jens Schmidt
//
// SPDX-License-Identifier: MPL-2.0

"use strict";

// polyfill the "browser" global for chromium compatibility
if ( (typeof globalThis.browser === "undefined") &&
     (typeof globalThis.chrome  !== "undefined") )
  globalThis.browser = chrome;

if ( (typeof Object.hasOwn === "undefined") )
  Object.hasOwn = (( o, p ) => (Object.prototype.hasOwnProperty.call( o, p )));

// loads the cooked add-on options or the raw local storage.
//
// If the first optional argument is a boolean with value true,
// this function returns the complete contents of the local
// storage unchanged.
//
// Otherwise, it returns an object having property keys identical
// to those of OPTION_METADATA and property values taken from the
// local storage, where possible, or otherwise sanitized to the
// option default values.
async function loadOptions( ...args )
{
  const cooked = (args.length === 0) ||
                 (typeof args[0] !== "boolean") ||
                 (! args.shift());

  const oo = await browser.storage.local.get( null );

  // return cooked options.  Treat anything fishy here as an
  // error, since function maintainAddOnOptions should have
  // sanitized the local storage already.
  if ( cooked ) {
    const on = {};
    for ( const [ option, { default: defval } ] of Object.entries( OPTION_METADATA ) )
      if ( ! Object.hasOwn( oo, option ) ) {
        console.error( `Defaulting option ${option} missing in local storage` );
        on[option] = defval;
      }
      else if ( typeof oo[option] !== typeof defval ) {
        console.error( `Defaulting option ${option} having invalid type in local storage` );
        on[option] = defval;
      }
      else
        on[option] = oo[option];
    return on;
  }

  // return the raw local storage
  else {
    return oo;
  }
}

// saves the cooked add-on options or overwrites the raw local
// storage.
//
// If the first optional argument is a boolean with value true,
// this function expects two additional arguments OO and OR.  It
// first writes the properties of object OO to the local storage
// and then removes all items specified in array OR from there.
//
// Otherwise, this function expectes one argument OO.  It selects
// those properties of object OO that look sane according to
// OPTION_METADATA and writes them to the local storage.
async function saveOptions( ...args )
{
  const cooked = (args.length === 0) ||
                 (typeof args[0] !== "boolean") ||
                 (! args.shift());

  const oo  = args[0];
  const or  = cooked ? null : args[1];

  // save the cooked options.  Again, treat anything fishy here
  // as an error.
  if ( cooked ) {
    const on = {};
    for ( const [ option, value ] of Object.entries( oo ) )
      if ( ! Object.hasOwn( OPTION_METADATA, option ) )
        console.error( `Not saving unknown option ${option} to local storage` );
      else if ( typeof value !== typeof OPTION_METADATA[option]["default"] )
        console.error( `Not saving option ${option} having invalid type to local storage` );
      else
        on[option] = value;
    await browser.storage.local.set( on );
  }

  // overwrite the raw local storage.  Do not care about
  // efficiency here, since this branch should only be executed
  // when this function is called from function
  // maintainAddOnOptions.
  else {
    await browser.storage.local.set( oo );
    await browser.storage.local.remove( or );
  }
}

const OPTION_VERSION = 1;

// define available options, their default values (from which we
// also derive the option value type), and some optional option
// handlers:
//
// - onchange( e ): called on change events of the option's input
//   element or when the option page is initialized or reset.  In
//   the latter case (and only that) the following holds:
//
//     typeof e.type === "undefined"
//
// - check( newValue, oldValue ): called when the option's value
//   has changed and is about to be saved.  Should return a pair
//   [ true, null ] if the new option value is OK, or otherwise a
//   pair
//
//     [ false, message | null ]
//
// (sync-mark-all-options)
const OPTION_METADATA = {

  in_input_elements: {
    default: false,
  },

  use_native_copy: {
    default: false,

    onchange: ( e ) => {
      const value = e.target.checked;
      document.getElementById( "trim_triple_clicks" ).disabled = value;
      document.getElementById( "multi_range_sep" ).disabled = value;
    },
  },

  trim_triple_clicks: {
    default: true,
  },

  multi_range_sep: {
    // do not try to be smart and use OS-dependent line endings
    // here.  After all, this option is dubbed "experimental".
    default: encodeURIComponent( "\n" ).toLowerCase(),

    check: ( value, _ ) => {
      try {
        decodeURIComponent( value );
        return [ true, null ];
      }
      catch ( e ) {
        return [ false, e.message ];
      }
    },
  },

};
