// background.js - copy-on-select-2 background script.
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

// maintains this add-on's options, possibly upgrades them,
// hopefully before any other code of this add-on executes
async function maintainAddOnOptions( details )
{
  const oo = await loadOptions( true );
  const on = {};
  const or = [];

  // determine current option set version, defaulting an absent
  // one to zero
  const osvers = Object.hasOwn( oo, "_version" ) ? oo["_version"] : 0;

  // determine new option values from local storage, defaulting
  // them as needed
  for ( const [ option, { default: defval } ] of Object.entries( OPTION_METADATA ) )
    if ( (Object.hasOwn( oo, option )) &&
         (typeof oo[option] === typeof defval) )
      on[option] = oo[option];
    else
      on[option] = defval;

  // mark unknown items in the local storage for removal
  for ( const option of Object.keys( oo ) )
    if ( (! Object.hasOwn( OPTION_METADATA, option )) &&
         (option !== "_version") )
      or.push( option );

  // update option set version
  on["_version"] = OPTION_VERSION;

  await saveOptions( true, on, or );
}

async function showOnboardingPage( details )
{
  if ( details.temporary ) return;
  if ( details.reason !== "install" ) return;
[% IF (equal relmode "final") -%]
  await browser.tabs.create(
    { url: "https://jschmidt.srht.site/copy-on-select-2/onboarding.html" } );
[% ELSE -%]
  await browser.tabs.create(
    { url: "https://jschmidt.srht.site/draft/copy-on-select-2/onboarding.html" } );
[% END -%]
}

browser.runtime.onInstalled.addListener( async ( details ) => {
  await maintainAddOnOptions( details );
  await showOnboardingPage( details );
} );
