// options.js - copy-on-select-2 option script.
//
// Copyright (C) 2023-2024 Jens Schmidt
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// This Source Code Form is “Incompatible With Secondary Licenses”, as
// defined by the Mozilla Public License, v. 2.0.

"use strict";

// polyfill the "browser" global for chromium compatibility
if ( (typeof globalThis.browser === "undefined") &&
     (typeof globalThis.chrome  !== "undefined") )
  globalThis.browser = chrome;

async function load()
{
  let o = await browser.storage.local.get();

  if ( o.in_input_elements )
    document.getElementById( "in_input_elements" ).checked = true;
}

function save( e )
{
  if ( e.target.id === "in_input_elements" )
    browser.storage.local.set( { in_input_elements: e.target.checked } );
}

document.addEventListener(
  "DOMContentLoaded",
  load,
  { once: true }
);

document.addEventListener(
  "input",
  save
);
