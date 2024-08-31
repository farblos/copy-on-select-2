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
  const oo = await loadLocalStorage();
  const on = {};

  for ( const [ option, defval ] of Object.entries( OPTIONS ) )
    if ( Object.hasOwn( oo, option ) )
      delete oo[option];
    else
      on[option] = defval;

  // default any new options in local storage
  if ( Object.keys( on ).length > 0 )
    await saveLocalStorage( on );

  // remove any unknown options from local storage
  if ( Object.keys( oo ).length > 0 )
    await cleanLocalStorage( Object.keys( oo ) );
}

async function showOnboardingPage( details )
{
  if ( details.temporary ) return;
  if ( details.reason !== "install" ) return;
  await browser.tabs.create(
    { url: "https://jschmidt.srht.site/copy-on-select-2/onboarding.html" } );
}

browser.runtime.onInstalled.addListener( async ( details ) => {
  await maintainAddOnOptions( details );
  await showOnboardingPage( details );
} );
