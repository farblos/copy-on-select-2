"use strict";

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
  { "once": true }
);

document.addEventListener(
  "input",
  save
);
