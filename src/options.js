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

// loads the option values from local storage and prepares the
// option page DOM accordingly.  Adds option documentation links
// referring to the add-on home page for all option labels.
async function load()
{
  const o = await loadOptions();

  for ( const [ option, { default: defval, onchange } ]
        of Object.entries( OPTION_METADATA ) ) {
    const otype = typeof defval;
    const oelt  = document.getElementById( option );

    if ( otype === "boolean" )
      oelt.checked = o[option];
    else
      oelt.value = o[option];

    if ( onchange ) {
      onchange( { target: oelt } );
      oelt.addEventListener( "change", onchange );
    }
  }

  // create and add option documentation links
  const hpurl = browser.runtime.getManifest().homepage_url;
  for ( const label of document.querySelectorAll( "label" ) ) {
    const slug =
          label.textContent.toLowerCase().
          replace( /[^ 0-9a-z-]/g, "" ).replace( / /g, "-" );
    const a = document.createElement( "a" );
    a.className = "option-doc";
    a.target    = "_blank";
    a.href      = `${hpurl}#${slug}`;
    const img = document.createElement( "img" );
    img.alt     = "Option Documentation Link";
    img.src     = "question-mark.svg";
    a.appendChild( img );
    label.insertAdjacentElement( "afterend", a );
  }
}

// determines which options have changed value on the option page
// DOM compared to the local storage.  Checks if all changed
// values are valid and, if so, saves them to the local storage,
// otherwise adds error parapraphs as needed.
async function save()
{
  const oo = await loadOptions();
  const on = {};

  // remove any previous error paragraphs
  for ( const p of document.querySelectorAll( "p.error" ) )
    p.remove();

  const errors = [];
  for ( const [ option, { default: defval, check } ]
        of Object.entries( OPTION_METADATA ) ) {
    const otype = typeof defval;
    const oelt  = document.getElementById( option );

    let value;
    if ( otype === "boolean" )
      value = oelt.checked;
    else
      value = oelt.value;

    let result, message;
    if      ( (value === oo[option]) )
      ; // no-op
    else if ( (typeof value !== otype) )
      errors.push( [ oelt, "invalid type" ] );
    else if ( (check) &&
              ([ result, message ] = check( value, oo[option] )) &&
              (! result) )
      errors.push( [ oelt, message ] );
    else
      on[option] = value;
  }

  // create and add error paragraphs as needed, otherwise save
  // all changed option values
  if ( errors.length > 0 )
    for ( const [ oelt, message ] of errors ) {
      const p = document.createElement( "p" );
      p.className   = "error";
      p.textContent = message ? `Invalid value (${message})` : "Invalid value";
      oelt.parentNode.insertAdjacentElement( "afterend", p );
    }
  else if ( Object.keys( on ).length > 0 )
    await saveOptions( on );
}

// resets all options to their default values as defined in
// OPTION_METADATA, both in the option page DOM and in the local
// storage
async function reset()
{
  const oo = await loadOptions();
  const on = {};

  // remove any previous error paragraphs
  for ( const p of document.querySelectorAll( "p.error" ) )
    p.remove();

  for ( const [ option, { default: defval, onchange } ]
        of Object.entries( OPTION_METADATA ) ) {
    const otype = typeof defval;
    const oelt  = document.getElementById( option );

    if ( otype === "boolean" )
      oelt.checked = defval;
    else
      oelt.value = defval;

    if ( onchange )
      onchange( { target: oelt } );

    if ( oo[option] !== defval )
      on[option] = defval;
  }

  if ( Object.keys( on ).length > 0 )
    await saveOptions( on );
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

document.getElementById( "reset" ).addEventListener(
  "click",
  reset
);
