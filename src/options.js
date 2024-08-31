// options.js - copy-on-select-2 option script.
//
// Copyright (C) 2023-2024 Jens Schmidt
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// SPDX-FileCopyrightText: 2023-2024 Jens Schmidt
//
// SPDX-License-Identifier: MPL-2.0

"use strict";

async function load()
{
  const o = await loadLocalStorage();

  for ( const [ option, defval ] of Object.entries( OPTIONS ) ) {
    const value = Object.hasOwn( o, option ) ? o[option] : defval;
    if ( typeof defval === "boolean" )
      document.getElementById( option ).checked = value;
    else
      document.getElementById( option ).value = value;
  }
}

async function save()
{
  const oo = await loadLocalStorage();
  const on = {};

  for ( const [ option, defval ] of Object.entries( OPTIONS ) ) {
    let value;
    if ( typeof defval === "boolean" )
      value = document.getElementById( option ).checked;
    else
      value = document.getElementById( option ).value;

    if ( (! Object.hasOwn( oo, option )) || (oo[option] !== value) )
      on[option] = value;
  }

  if ( Object.keys( on ).length > 0 )
    await saveLocalStorage( on );
}

document.addEventListener(
  "DOMContentLoaded",
  load,
  { once: true }
);

document.getElementById( "save" ).addEventListener(
  "click",
  save
);
