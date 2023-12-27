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
