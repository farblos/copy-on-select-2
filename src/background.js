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

// polyfill the "browser" global for chromium compatibility
if ( (typeof globalThis.browser === "undefined") &&
     (typeof globalThis.chrome  !== "undefined") )
  globalThis.browser = chrome;

browser.runtime.onInstalled.addListener( async ( { reason, temporary } ) => {
  if ( temporary ) return;
  if ( reason !== "install" ) return;
  await browser.tabs.create(
    { url: "https://jschmidt.srht.site/copy-on-select-2/onboarding.html" } );
} );
