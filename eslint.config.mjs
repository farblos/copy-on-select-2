// eslint.config.mjs - ESLint configuration file for copy-on-select-2.
//
// Copyright (C) 2025 Jens Schmidt
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// SPDX-FileCopyrightText: 2025 Jens Schmidt
//
// SPDX-License-Identifier: MPL-2.0

import js from "@eslint/js";
import globals from "globals";
import { defineConfig } from "eslint/config";

export default defineConfig(
  [
    {
      files: [ "*.js" ],

      plugins: { js },

      extends: [ "js/recommended" ],

      languageOptions: {
        sourceType: "script",

        globals: {
          ...globals.browser,
          ...globals.webextensions,
        },
      },

      rules: {
        "no-unused-vars": [
          "error",
          {
            argsIgnorePattern: "^_",
            varsIgnorePattern: "^_",
            caughtErrorsIgnorePattern: "^_",
          },
        ],

        // we need constants "true" and "false" with logical
        // operators to get reasonable indentation
        "no-constant-binary-expression": [ "off" ],

        "quotes": [ "error", "double" ],

        "semi": [ "error", "always" ],

        "linebreak-style": [ "error", "unix" ],
      },
    },
  ]
);

// Local Variables:
// mode: javascript
// End:
