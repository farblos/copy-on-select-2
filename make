#!/bin/bash
#
# Copyright (C) 2024 Jens Schmidt
#
# This file is free and unencumbered software released into the
# public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this file, either in source code form or as a
# compiled binary, for any purpose, commercial or non-commercial,
# and by any means.
#
# For more information, please refer to <http://unlicense.org/>.
#
# SPDX-FileCopyrightText: 2024 Jens Schmidt
#
# SPDX-License-Identifier: Unlicense

#
# make - low-dependency build script for copy-on-select-2.
#
# Overview
# ========
#
# Usage: make ["build-test"] target ("draft" | version)
# Targets: check => clean => build => dist => tag => upload => publish
#
# This script processes the following targets, where later
# targets generally imply execution of all previous ones
# (sync-mark-all-make-targets):
#
#   check    ensures build prerequisites
#   clean    removes known left-overs
#   build    creates artifacts (XPI and CRX)
#   dist     copies them to the local dist directory
#   tag      creates a lightweight or release tag
#   upload   uploads artifacts to SourceHut
#   publish  creates an (un)listed add-on version on AMO
#
# This script operates in one of the following different release
# modes:
#
# Draft Releases
# --------------
#
# To publish a draft release, call this build script as
#
#   ./make publish draft
#
# For draft releases this script automatically calculates a
# release version "2.N.M" based on existing Git tags.  This
# script processes draft releases locally only:
#
#   local: check => clean => build => dist => tag =>        => publish
#
# The "tag" target in the above sequence creates a light-weight
# tag, the "publish" target publishes the release on AMO as an
# unlisted version.
#
# Final Releases
# --------------
#
# To publish a final release, call this build script as
#
#   ./make publish 2.N
#
# where the version 2.N must be strictly larger than all other
# existing versions.  In addition, version 2.N must be maintained
# both in the version history of the readme and in the add-on
# manifest.
#
# For final releases, this script starts off locally but
# transfers control to the SourceHut build service by pushing an
# annotated tag corresponding to the released version.  Like
# this:
#
#   local: check => clean => build => dist => tag
#             _________________________________|
#            |
#            v
#   sr.ht: check => clean => build =>             => upload => publish
#
# On the SourceHut build service, the "publish" target updates
# the add-on metadata on AMO and publishes the release as listed
# version.
#
# Build-Test Releases
# -------------------
#
# As a special case for testing this build script only, there are
# btest releases, which you can trigger by a call
#
#   ./make build-test publish 2.N.M
#
# where the version 2.N.M must be strictly larger than all other
# existing versions.  This script processes a btest release like
# a final release, but publishes the release on AMO only as an
# unlisted version.
#
# Low-Dependency and Other Features
# =================================
#
# This build script intentionally uses as little external
# dependencies as reasonably possible.  It requires the usual
# standard Linux utilities, curl, git, gpg, jq, openssl, python
# (including the cryptography package), and the following more
# mundane dependencies:
#
# - markdown2, xsltproc (Debian packages: python3-markdown2,
#   xsltproc) to convert Markdown documentation to something that
#   can be published on AMO
#
# - cairosvg, URW Bookman fonts (Debian packages: cairosvg,
#   fonts-urw-base35) to convert the add-on icon from SVG to PNG
#
# - reuse (Debian package: reuse) to check adherence of this
#   project to the reuse specification
#
# The most outstanding dependency-avoider in this script is
# probably function zipcrx3, which creates CRX3 packages,
# replacing the whole Google protobuffer quatsch (15 packages,
# 10.2Mb on my system) by two functions consisting of less then
# 20 LOC.
#
# Other features and useful functions:
#
# - This script runs locally as well as on the SourceHut build
#   service.  In particular, it transparently handles OAUTH2
#   tokens and other secrets in both cases.
#
# - This script creates a version 2 manifest for the XPI package
#   and a version 3 manifest for the CRX package.  The sources
#   provide for an unpacked, temporary version 2 manifest add-on.
#
# - This script manages the complete add-on metadata on AMO, like
#   add-on description, add-on icon, version descriptions,
#   etc. from files stored in the add-on's Git repository.
#
# - This script should be xtrace-safe, security-wise: If you
#   switch on Bash tracing with "set -x", that setting is
#   temporarily switched off for code blocks processing sensitive
#   data.  That way security tokens and other sensitive data will
#   not leak into the build logs while still keeping as much
#   trace available as possible.  This is implemented by means of
#   functions pushx, popx, and curlx.
#
# - Function md2amohtml converts Markdown to the restricted AMO
#   HTML ("some HTML allowed").
#
# - Function amojwt calculates an AMO JWT from an AMO JWT issuer
#   and secret.
#
# Random Notes
# ============
#
# - This script tries as good as possible to create the XPI and
#   CRX packages in a reproducible manner.  But at least for
#   cairosvg it is not clear whether the icon rendering is fully
#   reproducible: It seems to be when done on one and the same
#   host, but not when done on different Debian distributions,
#   for example.
#
# Testing This Script
# ===================
#
# You can use environment variable TEST_BUILD to control some
# aspects of this script useful for testing.  Set it to a
# blank-separated list of one or more of the following keywords:
#
# - source
#
#   Assume that this script is sourced as a library and return
#   after all functions have been defined.  This is useful to
#   separately test the functions provided by this script.  Like
#   this:
#
#     TEST_BUILD=source
#     . ./make
#     amomd "Description en-US" < amo-metadata.md |
#     md2amohtml /root 2
#
# - xtrace
#
#   Enable Bash xtracing with "set -x".
#
# - nocutmp, nocubld
#
#   Do not clean up the temporary or build directory,
#   respectively, on exit.
#

#{{{ constants

ADDON_SLUG="copy-on-select-2"

SRHT_REPO_NAME="copy-on-select-2"

AMO_ADDONS_API_URL="https://addons.mozilla.org/api/v5/addons"

LOCAL_SECRETS_DIR=".secrets"
SRHT_SECRETS_DIR="$HOME/.secrets"

# identifiers used by function secret
SECID_SRHT_OAUTH2_TOKEN="jschmidt-srht.oauth2-token"
SECID_CRX3_SIGNING_KEY="farblos-crx3.pem"
SECID_AMO_JWT_ISSUER="farblos-amo.jwt-issuer"
SECID_AMO_JWT_SECRET="farblos-amo.jwt-secret"

LOCAL_DIST_DIR="dist"

#}}}

#{{{ testkwp

# returns whether the specified test keyword has been set in
# environment variable TEST_BUILD
testkwp()
{
  [[ " ${TEST_BUILD-} " == *" $1 "* ]]
}

#}}}

#{{{ error, usage, cerror

error()
{
  echo "$1" 1>&2
  exit 1
}

usage()
{
  echo "$1" 1>&2
  echo 1>&2
  echo "Usage: make [\"build-test\"] target (\"draft\" | version)" 1>&2
  echo "Targets: check => clean => build => dist => tag => upload => publish" 1>&2
  echo "  (later targets imply execution of all previous ones)" 1>&2
  exit 2
}

# reports a curl error related to the specified method and URL.
# Formats the specified response as prettily as possible.
cerror()
{
  printf 'Cannot %s on "%s"\n' "$1" "$2" 1>&2
  jq 0<<<"$3" 1>&2 2>/dev/null || printf '%s\n' "$3" 1>&2
  exit 1
}

#}}}

#{{{ secret, pushx, popx, curlx

# writes the specified secret to STDOUT.
#
# For local operation, this function expects the secret in a
# gpg-encrypted file named like the specified identifier and
# located below directory "$LOCAL_SECRETS_DIR".
#
# For operation on the SourceHut build service, this function
# expects the secret in a plain-text file named like the
# specified identifier and located below directory
# "$SRHT_SECRETS_DIR".  As a special case, this function writes
# the SourceHut-provided OAUTH2 token in environment variable
# OAUTH2_TOKEN to STDOUT when secret "$SECID_SRHT_OAUTH2_TOKEN"
# is requested.
secret()
{
  if   [[ $localp == 1 ]]; then
    gpg --quiet --decrypt "$LOCAL_SECRETS_DIR/$1"
  elif [[ $1 != "$SECID_SRHT_OAUTH2_TOKEN" ]]; then
    cat "$SRHT_SECRETS_DIR/$1"
  else
    # use "<<<" instead of echo or printf to stay xtrace-safe
    cat <<< "$OAUTH2_TOKEN"
  fi
}

# The following functions attempt to handle the xtrace without
# generating too much xtrace noise themselves.  That extra logic
# assumes that the xtrace is written to STDERR or, in other
# words, that variable BASH_XTRACEFD has not been fiddled with.
#
# For local operation, we redefine functions pushx and popx to
# trivial no-ops during initialization.

stackx=()

# switches off "set -x" tracing, remembering the current status
pushx()
{
  if [[ $- == *x* ]]; then
    set +x
    stackx+=( "set -x" )
  else
    stackx+=( ":" )
  fi
} 2>/dev/null # avoid trace noise for function pushx itself

# restores the status of "set -x" tracing from the matching pushx
# call
popx()
{
  if   [[ ${_popx_for_noise-} == 1 ]]; then
    unset _popx_for_noise
  elif [[ ${#stackx[@]} -gt 0 ]]; then
    local cmd=${stackx[${#stackx[@]} - 1]}
    unset 'stackx[${#stackx[@]} - 1]'
    _popx_for_noise=1
    $cmd
    popx 2>/dev/null # create trace noise for function popx itself
  fi
}

# calls curl on the specified commandline, stripping options
# "--pushx" and "--popx" from it and evaluating all arguments
# between these options as double-quoted strings.
#
# As an example, consider the following invocation of this
# function:
#
#   curlx --silent --fail-with-body                     \
#         -XPOST "$AMO_ADDONS_API_URL/upload/"          \
#         --pushx                                       \
#         -H 'Authorization: $( amojwt )'               \
#         --popx                                        \
#         -H "Content-Type: multipart/form-data"        \
#         -F upload=@"$file" -F channel="$channel"
#
# Since the authorization header is specified as a single-quoted
# string above, the referenced JWT will not be xtraced in the
# function call.  This function, the execution of which is not
# xtraced, turns that into something equivalent to following
# direct call to curl:
#
#   curl  --silent --fail-with-body                     \
#         -XPOST "$AMO_ADDONS_API_URL/upload/"          \
#         "-H" "Authorization: $( amojwt )"             \
#         -H "Content-Type: multipart/form-data"        \
#         -F upload=@"$file" -F channel="$channel"
curlx()
{
  pushx
  trap 'trap - RETURN; popx' RETURN

  local args=()

  local evalp=0
  while [[ $# -gt 0 ]]; do
    if   [[ $1 == "--pushx" ]]; then
      evalp=1
    elif [[ $1 == "--popx" ]]; then
      evalp=0
    elif [[ $evalp == 0 ]]; then
      args+=( "$1" )
    else
      eval "args+=( \"$1\" )"
    fi
    shift 1
  done

  curl "${args[@]}"

  # force trap execution, even if this function is executed as
  # sole command in a command substitution.  (Where the trap is
  # sort of pointless except for the message it generates.)  See
  # https://lists.gnu.org/archive/html/help-bash/2024-07/msg00007.html.
  return $?
}

#}}}

#{{{ nrmlzws

# normalizes whitespace on STDIN and writes the result to STDOUT.
# Unconditionally normalizes whitespace-only lines to empty
# lines.  Unconditionally trims leading and trailing empty lines
# and normalizes sequences of inner empty lines to one empty
# line.  If the input consists only of empty lines, this function
# reduces it to naught.
#
# With option "-i" this function normalizes intra-line
# whitespace.  With option "-n" this function removes the final
# newline after the last line.
nrmlzws()
{
  if [[ ! -f "$tdn/nrmlzws.awk" ]]; then
    cat << 'EOF' > "$tdn/nrmlzws.awk"
# previous line, normalization options
BEGIN {
  prevln = "";
  inlwsp = (nopts ~ / -i /);
  fnlnlp = (nopts ~ / -n /);
}

# normalize intra-line whitespace for whitespace-only and other
# lines
/^[\t ]+$/ {
  $0 = "";
}
(inlwsp) {
  sub( /^[\t ]+/, "" ); sub( /[\t ]+$/, "" ); gsub( /[\t ]+/, " " );
}

# unconditionally trim leading empty lines
(prevln == "" && $0 == "") {
  next;
}
(prevln == "") {
  prevln = $0; next;
}

# unconditionally normalize sequences of inner empty lines
($0 == "") {
  prevln = prevln "\n"; next;
}
{
  sub( /\n+$/, "\n", prevln );
  print prevln;
  prevln = $0; next;
}

# unconditionally trim trailing empty lines and conditionally
# even the final newline
END {
  if ( prevln != "" ) {
    sub( /\n+$/, "", prevln );
    if ( fnlnlp ) ORS = "";
    print prevln;
  }
}
EOF
  fi

  awk -v nopts=" $* " -f "$tdn/nrmlzws.awk"
}

#}}}

#{{{ versdesc

# reads the Markdown on STDIN and searches for the specified
# version in all level two sections called "Version History".  If
# the version is present, this function writes the first
# line-normalized description of it to STDOUT and returns true,
# otherwise it writes nothing to STDOUT and returns false.
#
# This function does not consider any nested Markdown constructs
# and assumes that every line starting with a sequence of hashes
# followed by a blank constitutes a section heading.
versdesc()
{
  if [[ ! -f "$tdn/versdesc.awk" ]]; then
    cat << 'EOF' > "$tdn/versdesc.awk"
BEGIN {
  invhistp = 0; invdescp = 0; versfndp = 0;
}

# limit execution of all following actions to the version history
(! invhistp) && (/^## Version History$/) {
  invhistp = 1; next;
}
(! invhistp) {
  next;
}
(invhistp) && (/^#+ /) {
  invhistp = 0; next;
}

# limit execution of all following actions to the first history
# entry having the specified version (but do print the version
# heading here)
(! invdescp) && (! versfndp) && ($0 == "Version " version) {
  invdescp = 1; versfndp = 1; print; next;
}
(! invdescp) {
   next;
}
(invdescp) && (/^Version 2(\.[1-9][0-9]*){1,2}$/) {
   invdescp = 0; next;
}

{ print; }

END {
  if ( ! versfndp ) exit 1;
}
EOF
  fi

  awk -v version="$1" -f "$tdn/versdesc.awk" |
  nrmlzws ||
  return 1
}

#}}}

#{{{ amomd

# reads the Markdown on STDIN and searches for a level one
# section with the specified title.  If such a section is
# present, this function writes the line-normalized contents of
# the first one to STDOUT and returns true, otherwise it writes
# nothing to STDOUT and returns false.
#
# This function does not consider any nested Markdown constructs
# and assumes that every line starting with a sequence of hashes
# followed by a blank constitutes a section heading.
amomd()
{
  if [[ ! -f "$tdn/amomd.awk" ]]; then
    cat << 'EOF' > "$tdn/amomd.awk"
BEGIN {
  insectp = 0; sectfndp = 0;
}

# limit execution of all following actions to the first section
# having the specified title
(! insectp) && (! sectfndp) && ($0 == "# " title) {
  insectp = 1; sectfndp = 1; next;
}
(! insectp) {
  next;
}
(insectp) && (/^# /) {
  insectp = 0; next;
}

{ print; }

END {
  if ( ! sectfndp ) exit 1;
}
EOF
  fi

  awk -v title="$1" -f "$tdn/amomd.awk" |
  nrmlzws ||
  return 1
}

#}}}

#{{{ md2amohtml

# reads the Markdown on STDIN, converts it to XML, selects all
# nodes matching the specified root XPath, converts them to HTML
# allowed by AMO ("some HTML allowed"), and writes the latter to
# STDOUT.
#
# AMO renders all newlines in AMO HTML as hard breaks, so this
# function goes into some details to handle these in a way such
# that the result is visually pleasing:
#
# - It replaces all newlines in non-ws-only text nodes by blanks.
#
# - It keeps ws-only text nodes not containing any newlines
#   unchanged.
#
# - It keeps ws-only text nodes containing newlines below the
#   specified whitespace level unchanged.
#
# - It replaces any remaining ws-only text nodes containing
#   newlines by a single newline.
#
# This effectively means that (of course also depending on the
# Markdown converter) all paragraph and other nodes below the
# specified level are separated by an empty line while all others
# are layed out immediately following each other.
md2amohtml()
{
  if [[ ! -f "$tdn/xml2amohtml.xslt" ]]; then
    cat << 'EOF' > "$tdn/xml2amohtml.xslt"
<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:param name="root"/>
  <xsl:param name="wslevel"/>

  <!-- select new root nodes -->
  <xsl:template match="/">
    <xsl:apply-templates select="$root">
      <xsl:with-param name="level" select="0"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="node()">
    <xsl:param name="level"/>
    <xsl:choose>

      <!-- process allowed AMO HTML nodes -->
      <xsl:when test="self::a|self::abbr|self::acronym">
        <xsl:copy>
          <xsl:for-each select="@href|@title">
            <xsl:copy select="."/>
          </xsl:for-each>
          <xsl:apply-templates select="node()">
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="self::b|self::blockquote|self::code|self::em|self::i|self::li|self::ol|self::strong|self::ul">
        <xsl:copy>
          <xsl:apply-templates select="node()">
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>

      <!-- replace newlines in non-whitespace-only text ... -->
      <xsl:when test="self::text()[normalize-space()]">
        <xsl:value-of select="translate(., '&#10;', ' ')"/>
      </xsl:when>

      <!-- ... and normalize remaining whitespace-only text
        == depending on the whitespace level -->
      <xsl:when test="self::text() and $level &lt; $wslevel">
        <xsl:copy/>
      </xsl:when>
      <xsl:when test="self::text() and contains(., '&#10;')">
        <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="self::text()">
        <xsl:copy/>
      </xsl:when>

      <!-- drop all remaining non-element nodes -->
      <xsl:when test="not(self::*)"/>

      <!-- replace remaining element nodes by their contents -->
      <xsl:otherwise>
        <xsl:apply-templates select="node()">
          <xsl:with-param name="level" select="$level + 1"/>
        </xsl:apply-templates>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
EOF
  fi

  # execute above stylesheet on whatever the Markdown converter
  # produces.  Be careful not to introduce extra newlines in the
  # intermediate XML.
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo -n '<root>'
    markdown2 -x markdown-in-html | nrmlzws -n
    echo -n '</root>'
  } |
  xsltproc --nonet                              \
           --param root "$1"                    \
           --param wslevel "$2"                 \
           "$tdn/xml2amohtml.xslt" - |
  nrmlzws -i
}

#}}}

#{{{ amojwt

# generates an AMO JWT from the JWT issuer and secret in global
# variables jwtiss and jwtsec, respectively, and prints it as a
# JWT header to STDOUT.  See https://jwt.io,
# https://mozilla.github.io/addons-server/topics/api/auth.html.
amojwt()
{
  pushx

  local iss=$jwtiss
  local sec=$jwtsec

  local jti; jti=$( dd status=none if=/dev/urandom bs=1 count=30 |
                    base64 -w 0 | tr '+/' '-_' | tr -d '=' )

  local now; now=$( date '+%s' )
  local iat; iat=$(( now - 10  ))
  local exp; exp=$(( now + 150 - 10 ))

  local hdr; hdr=$( printf '%s' '{"alg":"HS256","typ":"JWT"}' |
                    base64 -w 0 | tr '+/' '-_' | tr -d '=' )
  local pld; pld=$( printf '%s' '{"iss":"'"$iss"'","jti":"'"$jti"'",
                                  "iat":'"$iat"',"exp":'"$exp"'}' |
                    base64 -w 0 | tr '+/' '-_' | tr -d '=' )
  local sig; sig=$( printf '%s' "$hdr.$pld" |
                    openssl dgst -binary -sha256 -mac hmac -macopt key:"$sec" |
                    base64 -w 0 | tr '+/' '-_' | tr -d '=' )

  echo "JWT $hdr.$pld.$sig"

  popx
}

#}}}

#{{{ zipcrx3

# creates a zip archive from the files in the current working
# directory and writes it to STDOUT.  If there is a signature key
# on STDIN, this function reads it and uses it to sign the zip
# archive, resulting in a CRX3 package.  The latter part has been
# inspired by https://github.com/pawliczka/CRX3-Creator.
zipcrx3()
{
  if [[ ! -f "$tdn/zipcrx3.py" ]]; then
    cat << 'EOF' > "$tdn/zipcrx3.py"
import io
import os
import struct
import sys
import zipfile

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, utils

# convert the specified non-negative integer to a protobuf varint
# and append it to the specified bytearray
def pbvi( i, pbba ):
    while i > 127:
        r, i = i % 128, i // 128
        pbba.append( r | 128 )
    pbba.append( i )

# convert the specfied bytes-like to a protobuf record with the
# specified field number and wire type LEN (== 2).  Return the
# record as a bytearray.
def pbr( fno, bs ):
    pbba = bytearray()
    pbvi( (fno << 3) | 2, pbba )
    pbvi( len( bs ),      pbba )
    pbba.extend( bs )
    return pbba

# determine archive members from the current working directory,
# stripping off any leading "./" prefix
ams = [];
for bdn, _, fns in os.walk( "." ):
    for fn in fns:
        ams.append( os.path.relpath( os.path.join( bdn, fn ), "." ) )

# create archive text in memory
at = io.BytesIO()
with zipfile.ZipFile( at, "w", zipfile.ZIP_DEFLATED ) as zf:
    for am in sorted( ams ): zf.write( am )
at = at.getvalue()

if (pem := sys.stdin.buffer.read()) and (len( pem ) > 0):
    SHA256 = hashes.SHA256()

    # convert the private key to a key object
    key = serialization.load_pem_private_key( pem, password = None )

    # determine public key from private key
    der = key.public_key().public_bytes(
        encoding = serialization.Encoding.DER,
        format = serialization.PublicFormat.SubjectPublicKeyInfo
    )

    # determine CRX Id
    digest = hashes.Hash( SHA256 )
    digest.update( der )
    crxid = pbr( 1, digest.finalize()[0:16] )

    # determine CRX signature
    digest = hashes.Hash( SHA256 )
    digest.update( b'CRX3 SignedData\00' )
    digest.update( struct.pack( "<I", len( crxid ) ) )
    digest.update( crxid )
    digest.update( at )
    crxsg = key.sign(
        digest.finalize(),
        padding.PKCS1v15(),
        utils.Prehashed( SHA256 )
    )

    # determine CRX header
    crxhd = (pbr( 2,     pbr( 1, der ) + pbr( 2, crxsg ) ) +
             pbr( 10000, crxid ))

    # write CRX to STDOUT
    sys.stdout.buffer.write( b"Cr24" )                # magic
    sys.stdout.buffer.write( struct.pack( "<I", 3 ) ) # version
    sys.stdout.buffer.write( struct.pack( "<I", len( crxhd ) ) )
    sys.stdout.buffer.write( crxhd )
    sys.stdout.buffer.write( at )
else:
    sys.stdout.buffer.write( at )
EOF
  fi

  # ensure reproducible builds and force a defined timezone on
  # the python3 interpreter, which has an effect at least on the
  # conversion from Unix file modification timestamps to zip
  # archive member timestamps
  TZ="UTC" python3 "$tdn/zipcrx3.py"
}

#}}}

set -e
set -u
set -o pipefail
shopt -s lastpipe

# establish a minimal working environment when being sourced and
# immediately return
if testkwp source; then
  set +e
  localp=1
  tdn="/tmp/make-test-$$"
  rm -rf "$tdn" && mkdir "$tdn"
  return
fi

if testkwp xtrace; then
  set -x
fi

#{{{ commandline parameter processing

btestp=
if [[ ($# -gt 0) && ($1 == "build-test") ]]; then
  btestp=1
  shift 1
else
  btestp=0
fi

# (sync-mark-all-make-targets)
target=
if   [[ $# == 0 ]]; then
  usage "No target specified."
elif [[ $1 =~ ^(check|clean|build|dist|tag|upload|publish)$ ]]; then
  target=$1
  shift 1
else
  usage "Invalid target \"$1\" specified."
fi

uversion=
if   [[ $# == 0 ]]; then
  usage "No version specified."
elif [[ $1 == "draft" ]]; then
  uversion=$1
  shift 1
elif [[ $1 =~ ^2(\.[1-9][0-9]*){1,2}$ ]]; then
  uversion=$1
  shift 1
else
  usage "Invalid version \"$1\" specified."
fi

if [[ $# -gt 0 ]]; then
  usage "Extra commandline parameters \"$*\" specified."
fi

#}}}

#{{{ initialization

# determine and verify current CI
localp=
case ${CI_NAME-local} in
  (local)     localp=1 ;;
  (sourcehut) localp=0 ;;
  (*) error "Cannot process CI \"$CI_NAME\"." ;;
esac

# redefine functions related to xtrace for local operation
if [[ $localp == 1 ]]; then
  pushx() { :; } 2>/dev/null
  popx()  { :; } 2>/dev/null
fi

# determine maximum released version and maximum draft version
# for that released version from Git tags.  If there is no
# released version version yet, default that to "2.0", if there
# is no draft version yet, default that to "$mrvers.0".
mrvers=$( git for-each-ref --format '%(objecttype) %(refname)' 'refs/tags/v*' |
          awk 'BEGIN { print "2.0" }
               ($1 == "tag") && ($2 ~ /^refs\/tags\/v2\.[1-9][0-9]*$/) {
                 sub( "^refs/tags/v", "", $2 ); print $2;
               }' |
          sort -V | tail -n 1 )
mdvers=$( git for-each-ref --format '%(objecttype) %(refname)' 'refs/tags/v*' |
          awk 'BEGIN { print "'"$mrvers"'.0" }
               (index( $2, "refs/tags/v'"$mrvers"'." ) == 1) {
                 sub( "^refs/tags/v", "", $2 ); print $2;
               }' |
          sort -V | tail -n 1 )

# determine release mode and version.
#
# For draft releases, just use the maximum draft version plus
# one as release version.
#
# For final and btest releases, use the version specified on the
# commandline, ensuring that it is strictly larger than the
# maximum released or draft version (when called locally) or
# equal to the maximum released or draft version (when called on
# the SourceHut build service).
#
# Keep the version regexps in the build workflow in sync with the
# version regexps used below.
relmode=
version=
if   [[ $localp == 1 ]] &&
     [[ $btestp == 0 ]] &&
     [[ $uversion == "draft" ]]; then
  relmode="draft"
  version=$( awk -v FS=. -v OFS=. '{ $3++; print $0; }' <<< "$mdvers"  )
elif [[ $localp == 1 ]] &&
     [[ $btestp == 0 ]] &&
     [[ $uversion =~ ^2\.[1-9][0-9]*$ ]] &&
     [[ $uversion != "$mrvers" ]] &&
     sort -C -V <<< "$mrvers"$'\n'"$uversion"; then
  relmode="final"
  version=$uversion
elif [[ $localp == 1 ]] &&
     [[ $btestp == 1 ]] &&
     [[ $uversion =~ ^2\.[1-9][0-9]*\.[1-9][0-9]*$ ]] &&
     [[ $uversion != "$mdvers" ]] &&
     sort -C -V <<< "$mdvers"$'\n'"$uversion"; then
  relmode="btest"
  version=$uversion
elif [[ $localp == 0 ]] &&
     [[ $btestp == 0 ]] &&
     [[ $uversion == "$mrvers" ]]; then
  relmode="final"
  version=$uversion
elif [[ $localp == 0 ]] &&
     [[ $btestp == 1 ]] &&
     [[ $uversion == "$mdvers" ]]; then
  relmode="btest"
  version=$uversion
else
  error "Invalid version \"$uversion\" specified."
fi

# prepare for cleanup
cutrap=':'
trap 'set +e;'"$cutrap" EXIT
trap 'exit 2' HUP INT QUIT

# create temporary and build directory.  These better should have
# absolute paths.
tdn=$( mktemp -t -p /tmp -d "tmp.XXXXXXXXXX" )
if ! testkwp nocutmp; then
  cutrap='rm -rf "$tdn";'"$cutrap"
  trap 'set +e;'"$cutrap" EXIT
fi
bdn=$( mktemp -t -p /tmp -d "build.XXXXXXXXXX" )
if ! testkwp nocubld; then
  cutrap='rm -rf "$bdn";'"$cutrap"
  trap 'set +e;'"$cutrap" EXIT
fi

# determine v-prefixed version, XPI base name, CRX base name
vversion="v$version"
xpibname="${ADDON_SLUG}-unsigned-$version.xpi"
crxbname="${ADDON_SLUG}-$version.crx"

# determine whether our working tree is clean (always consider
# non-local working trees clean)
cleanp=
if   [[ $localp == 0 ]]; then
  cleanp=1
elif # check for staged but uncomitted changes
     git diff-index --quiet --cached HEAD -- &&
     # check for unstaged changes
     git diff-files --quiet &&
     # check for untracked files
     ! git ls-files --exclude-standard --others |
       grep . > /dev/null; then
  cleanp=1
else
  cleanp=0
fi

#}}}

#{{{ target check

# ensure a reasonable Git status before processing a non-draft
# release.  On the SourceHut build service, the working tree has
# a detached head, so do not check the branch name there.
if [[ ($relmode != "draft") &&
      ($cleanp == 0) ]]; then
  error "Cannot process unclean working tree."
fi
if [[ ($localp == 1) &&
      ($relmode == "final") &&
      ($( git rev-parse --abbrev-ref HEAD ) != "main") ]]; then
  error "Cannot process non-main branch."
fi

# ensure a clean reuse specification status
if [[ $relmode != "draft" ]] &&
   ! reuse lint; then
  error "Cannot process unclean reuse status."
fi

# create a comment-free version of the add-on manifest, since jq
# objects to comments
sed '\@^ *//@d' "src/manifest.json" > "$tdn/manifest.json"

# ensure a sane manifest version
mfversion=$( jq -r '.manifest_version' "$tdn/manifest.json" )
if [[ $mfversion != 2 ]]; then
  error "Cannot process manifest version \"$mfversion\"."
fi

# ensure presence of the release version in the manifest for
# non-draft releases.  For draft releases, we modify the manifest
# in target "build".
if [[ $relmode != "draft" ]]; then
  mversion=$( jq -r '.version' "$tdn/manifest.json" )
  if [[ $mversion != "$version" ]]; then
    error "Cannot find version \"$version\" in manifest."
  fi
fi

# ensure presence of a description for the release version in the
# readme for non-draft releases and extract it as release
# description
if [[ $relmode != "draft" ]] &&
   ! versdesc "$version" < README.md > "$tdn/reldesc.md"; then
  error "Cannot find version \"$version\" in version history."
fi

# ensure presence of the AMO add-on ID in the manifest and
# determine it in an URI-encoded way
if ! amoextid=$( jq -er '.browser_specific_settings.gecko.id |
                         if . then @uri else . end' \
                        "$tdn/manifest.json" ); then
  error "Cannot find AMO add-on ID in manifest."
fi

[[ $target == "check" ]] && exit 0

#}}}

#{{{ target clean

# (sync-mark-left-over-files)
rm -f content/*~
rm -f content/copy-on-select-2-[0-9][0-9].png
rm -f content/copy-on-select-2-notext.svg
rm -f src/*~
rm -f src/copy-on-select-2-128.png
rm -f src/copy-on-select-2-32.png
rm -f src/copy-on-select-2-64.png

[[ $target == "clean" ]] && exit 0

#}}}

#{{{ target build

# copy the sources to separate build directories, one for the XPI
# and one for the CRX
cp -Rp src "$bdn/xpi"
cp -Rp src "$bdn/crx"

# for the CRX create the service worker from the background
# scripts by concatenating all these and storing the result using
# the name of the last background script.  This does not take
# care about removing former background scripts that otherwise
# would not be required in the CRX any more.
eval "declare -a bgsns=(
  $( jq -r '.background.scripts[] | @sh' "$tdn/manifest.json" )
)"
cat "${bgsns[@]/#/src/}" > "$bdn/crx/${bgsns[-1]}"

# modify the add-on manifest as needed:
#
# - For draft releases set the add-on version in the manifest to
#   the release version we have determined during initialization;
#
# - for the CRX use a version 3 manifest and simplify the
#   background scripts to a service worker.
#
# Process license header and comment-free manifest separately
# from each other to not upset jq.
for addontype in "xpi" "crx"; do
  {
    sed -n '1,/^$/p' src/manifest.json;
    sed '1,/^$/d; \@^ *//@d' src/manifest.json |
    if [[ $relmode == "draft" ]]; then
      jq '.version = "'"$version"'"'
    else
      cat
    fi |
    if [[ $addontype == "crx" ]]; then
      jq '.manifest_version = 3 |
          .background = {
            "service_worker": .background.scripts[-1]
          }'
    else
      cat
    fi
  } > "$bdn/$addontype/manifest.json"
done

# create the add-on icons from the SVG.  At least Firefox does
# not seem to use these for add-ons published on AMO, though.
#
# We potentially need the 128-pixel-sized icon also later when
# updating the add-on metadata on AMO.
for pixels in 32 64 128; do
  cairosvg --output-width $pixels               \
           --output-height $pixels              \
           --background white                   \
           --format png                         \
           "${ADDON_SLUG}.svg"                  \
           -o "$tdn/${ADDON_SLUG}-$pixels.png"
  cp -p "$tdn/${ADDON_SLUG}-$pixels.png"        \
        "$bdn/xpi/${ADDON_SLUG}-$pixels.png"
  cp -p "$tdn/${ADDON_SLUG}-$pixels.png"        \
        "$bdn/crx/${ADDON_SLUG}-$pixels.png"
done

# ensure reproducible builds and normalize file and directory
# modification times to the commit time of the current head.  It
# would have been cleaner to do that in function zipcrx3, but the
# ZipFile class does not seem to support this easily.
cts=$( git show --no-patch --format='%ct' HEAD )
find "$bdn/xpi" -execdir touch -d "@$cts" '{}' +
find "$bdn/crx" -execdir touch -d "@$cts" '{}' +

# create XPI
cat /dev/null |
( cd "$bdn/xpi" && zipcrx3 ) > "$bdn/$xpibname"

# create CRX
secret "$SECID_CRX3_SIGNING_KEY" |
( cd "$bdn/crx" && zipcrx3 ) > "$bdn/$crxbname"

[[ $target == "build" ]] && exit 0

#}}}

#{{{ target dist

if [[ $localp == 1 ]]; then
  rm -f "$LOCAL_DIST_DIR/$xpibname"
  cp -p "$bdn/$xpibname" "$LOCAL_DIST_DIR/$xpibname"
  chmod 0444 "$LOCAL_DIST_DIR/$xpibname"
  rm -f "$LOCAL_DIST_DIR/$crxbname"
  cp -p "$bdn/$crxbname" "$LOCAL_DIST_DIR/$crxbname"
  chmod 0444 "$LOCAL_DIST_DIR/$crxbname"
fi

[[ $target == "dist" ]] && exit 0

#}}}

#{{{ target tag

if [[ $localp == 1 ]]; then
  # for a draft release, tag the current head with a lightweight
  # tag, mostly to keep track of available draft releases
  if [[ $relmode == "draft" ]]; then
    git tag --no-sign "$vversion" HEAD
  fi

  # for a non-draft release, tag the current head with an
  # annotated tag and push that tag, thus continuing the release
  # process on the SourceHut build service
  if [[ $relmode != "draft" ]]; then
    git tag --sign --annotate --file "$tdn/reldesc.md" "$vversion" HEAD
    git push origin "$vversion"
    exit 0
  fi
fi

[[ $target == "tag" ]] && exit 0

#}}}

#{{{ target upload

# requires permissions
#
#   git.sr.ht/OBJECTS:RW
#   git.sr.ht/PROFILE:RO
#   git.sr.ht/REPOSITORIES:RO
#   meta.sr.ht/PROFILE:RO
if [[ $relmode != "draft" ]]; then
  pushx
  # shellcheck disable=SC2034
  oat=$( secret "$SECID_SRHT_OAUTH2_TOKEN" )
  popx

  rsp=$(
    # define the GraphQL query ...
    cat << '    EOF' |
    query
    repoId( $repoName: String! ) {
      me {
        repository( name: $repoName ) {
          id
        }
      }
    }
    EOF
    # ... convert it and the scalar input variables to JSON ...
    jq --null-input --compact-output                            \
       --rawfile query    /dev/stdin                            \
       --arg     repoName "$SRHT_REPO_NAME"                     \
       '{
          "query": $query,
          "variables": { "repoName": $repoName }
       }' |
    # ... and send the request
    curlx --silent --fail-with-body                             \
          --pushx                                               \
          --oauth2-bearer '$oat'                                \
          --popx                                                \
          -XPOST 'https://git.sr.ht/query'                      \
          -H "Content-Type: application/json"                   \
          -d @- |
    # extract what we are looking for.  If it is not there, pipe
    # through everything to not loose any error messages.
    jq --compact-output '.data.me.repository.id // .' ) ||
  cerror POST 'https://git.sr.ht/query#repoId' "$rsp"
  if [[ $rsp =~ ^[0-9]+$ ]]; then
    repoid=$rsp
  else
    cerror POST 'https://git.sr.ht/query#repoId-result' "$rsp"
  fi

  for file in "$bdn/$xpibname" "$bdn/$crxbname"; do
    rsp=$(
      # define the GraphQL query ...
      cat << '      EOF' |
      mutation
      upload( $repoId: Int!, $revspec: String!, $file: Upload! ) {
        uploadArtifact( repoId: $repoId, revspec: $revspec, file: $file ) {
          id
        }
      }
      EOF
      # ... convert it and the scalar input variables to JSON ...
      jq --null-input --compact-output                          \
         --rawfile query   /dev/stdin                           \
         --argjson repoId  $repoid                              \
         --arg     revspec "$vversion"                          \
         '{
            "query": $query,
            "variables": { "repoId":  $repoId,
                           "revspec": $revspec,
                           "file":    null }
         }' |
      # ... add the file to be uploaded and send the request
      curlx --silent --fail-with-body                           \
            --pushx                                             \
            --oauth2-bearer '$oat'                              \
            --popx                                              \
            -XPOST 'https://git.sr.ht/query'                    \
            -H "Content-Type: multipart/form-data"              \
            -F operations=@-                                    \
            -F map='{ "0": [ "variables.file" ] }'              \
            -F 0=@"$file" |
      # extract what we are looking for.  If it is not there, pipe
      # through everything to not loose any error messages.
      jq --compact-output '.data.uploadArtifact.id // .' ) ||
    cerror POST 'https://git.sr.ht/query#upload' "$rsp"
    if [[ ! $rsp =~ ^[0-9]+$ ]]; then
      cerror POST 'https://git.sr.ht/query#upload-result' "$rsp"
    fi
  done
fi

[[ $target == "upload" ]] && exit 0

#}}}

#{{{ target publish

pushx
jwtiss=$( secret "$SECID_AMO_JWT_ISSUER" )
jwtsec=$( secret "$SECID_AMO_JWT_SECRET" )
popx

channel=
if [[ $relmode == "final" ]]; then
  channel=listed
else
  channel=unlisted
fi

# unconditionally update the add-on metadata for non-draft
# releases
if [[ $relmode != "draft" ]]; then
  lcdopts=()
  # at least here we need the effect of Bash option "lastpipe"
  sed -rn 's/^# Description (.+)$/\1/p' amo-metadata.md |
  while IFS= read -r lcode; do
    # extract the description and convert it to AMO HTML in a
    # temporary file
    amomd "Description $lcode" < amo-metadata.md |
    md2amohtml /root 2 > "$tdn/amodesc-$lcode.html"

    # build jq commandline options to pass the contents of that
    # temporary file as variable to jq
    lcdid="desc_${lcode//[!0-9A-Za-z]/_}"
    lcdopts+=( --rawfile "$lcdid" "$tdn/amodesc-$lcode.html" )
  done

  rsp=$( amomd "Non-Description Metadata" < amo-metadata.md |
         jq --null-input --compact-output                       \
            --from-file /dev/stdin                              \
            "${lcdopts[@]}" |
         curlx --silent --fail-with-body                        \
               -XPATCH "$AMO_ADDONS_API_URL/addon/$amoextid/"   \
               --pushx                                          \
               -H 'Authorization: $( amojwt )'                  \
               --popx                                           \
               -H "Content-Type: application/json"              \
               -d @- ) ||
  cerror PATCH "$AMO_ADDONS_API_URL/addon/$amoextid#md" "$rsp"
  if ! jq -e '.guid' 0<<<"$rsp" 1>/dev/null; then
    cerror PATCH "$AMO_ADDONS_API_URL/addon/$amoextid#md-result" "$rsp"
  fi
fi

# unconditionally update the add-on icon for non-draft releases.
# Using the API here is not better or worse than the BUI: In both
# cases you can upload only one icon, and not one per different
# size.
if [[ $relmode != "draft" ]]; then
  rsp=$( curlx --silent --fail-with-body                        \
               -XPATCH "$AMO_ADDONS_API_URL/addon/$amoextid/"   \
               --pushx                                          \
               -H 'Authorization: $( amojwt )'                  \
               --popx                                           \
               -H "Content-Type: multipart/form-data"           \
               -F icon=@"$tdn/${ADDON_SLUG}-128.png" ) ||
  cerror PATCH "$AMO_ADDONS_API_URL/addon/$amoextid#icon" "$rsp"
  if ! jq -e '.guid' 0<<<"$rsp" 1>/dev/null; then
    cerror PATCH "$AMO_ADDONS_API_URL/addon/$amoextid#icon-result" "$rsp"
  fi
fi

# upload XPI to AMO and determine the resulting upload UUID
rsp=$( curlx --silent --fail-with-body                          \
             -XPOST "$AMO_ADDONS_API_URL/upload/"               \
             --pushx                                            \
             -H 'Authorization: $( amojwt )'                    \
             --popx                                             \
             -H "Content-Type: multipart/form-data"             \
             -F upload=@"$bdn/$xpibname" -F channel="$channel" ) ||
cerror POST "$AMO_ADDONS_API_URL/upload/" "$rsp"
if ! uuuid=$( jq -er '.uuid | if . then @uri else . end' 0<<<"$rsp" ); then
  cerror POST "$AMO_ADDONS_API_URL/upload#result" "$rsp"
fi

# poll for the XPI to be validated.  Use timing parameters as
# recommended by the AMO documentation, see section "Uploading
# the add-on file" in the Mozilla add-ons community blog "A new
# API for submitting and updating add-ons".  With no short link
# available.
for (( timeout = 1; timeout <= 60; timeout++ )); do
  sleep 10
  rsp=$( curlx --silent --fail-with-body                        \
               -XGET "$AMO_ADDONS_API_URL/upload/$uuuid/"       \
               --pushx                                          \
               -H 'Authorization: $( amojwt )'                  \
               --popx ) ||
  cerror GET "$AMO_ADDONS_API_URL/upload/$uuuid/" "$rsp"
  if jq -e '.valid' 0<<<"$rsp" 1>/dev/null; then
    timeout=0
    break
  fi
done
if [[ $timeout != 0 ]]; then
  cerror GET "$AMO_ADDONS_API_URL/upload/$uuuid#timeout" "$rsp"
fi

# create a new add-on version from the uploaded XPI.  This step
# is undoable and, hence, must come last in this build script.
rsp=$( # generate the release description as AMO HTML ...
       if [[ $relmode != "draft" ]]; then
         md2amohtml '/root/node()[position()>1]' 0 < "$tdn/reldesc.md"
       else
         echo -n "Unlisted draft release $version."
       fi |
       # ... convert it and the scalar input variables to JSON
       # ...
       jq --null-input --compact-output                         \
          --rawfile reldesc /dev/stdin                          \
          --arg     uuuid   "$uuuid"                            \
          '{
             "compatibility": [ "firefox" ],
             "license":       "MPL-2.0",
             "release_notes": { "en-US": $reldesc },
             "upload":        $uuuid
          }' |
       # ... and send the request
       curlx --silent --fail-with-body                                  \
             -XPOST "$AMO_ADDONS_API_URL/addon/$amoextid/versions/"     \
             --pushx                                                    \
             -H 'Authorization: $( amojwt )'                            \
             --popx                                                     \
             -H "Content-Type: application/json"                        \
             -d @- ) ||
cerror POST "$AMO_ADDONS_API_URL/addon/$amoextid/versions/" "$rsp"
chnlvers=$( jq -r '.channel + ":" + .version' 0<<<"$rsp" )
if [[ $chnlvers != "$channel:$version" ]]; then
  cerror POST "$AMO_ADDONS_API_URL/addon/$amoextid/versions#result" "$rsp"
fi

[[ $target == "publish" ]] && exit 0

#}}}

exit 0
