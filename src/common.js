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
  Object.hasOwn = (( o, p ) => Object.prototype.hasOwnProperty.call( o, p ));

// provide polyfilling wrappers to access the local storage
function loadLocalStorage()
{
  try {
    return browser.storage.local.get( null );
  }
  catch ( e ) {
    return new Promise( ( resolve ) =>
      browser.storage.local.get( null, resolve ) );
  }
}

function saveLocalStorage( o )
{
  try {
    return browser.storage.local.set( o );
  }
  catch ( e ) {
    return new Promise( ( resolve ) =>
      browser.storage.local.set( o, resolve ) );
  }
}

function cleanLocalStorage( o )
{
  try {
    return browser.storage.local.remove( o );
  }
  catch ( e ) {
    return new Promise( ( resolve ) =>
      browser.storage.local.remove( o, resolve ) );
  }
}

// define available options and their default values (from which
// we also derive the option value type) (sync-mark-all-options)
const OPTIONS = {
  in_input_elements: false,

  trim_triple_clicks: true,

  // do not try to be smart and use OS-dependent line endings
  // here.  After all, this option is dubbed "experimental".
  multi_range_sep: encodeURIComponent( "\n" ).toLowerCase()
};
