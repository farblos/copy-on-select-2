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
# GNUmakefile - stub makefile for copy-on-select-2.
#
# This is a convenience stub makefile so that one can execute
# "make publish draft" instead of "./make publish draft".  This
# hack works as long as the commandline does not contain any
# parameters starting with a "-" or containing an "=".
#

# (sync-mark-all-make-targets)
TARGETS := check clean build dist tag upload publish

# handle all real targets (coming first on the commandline) and
# forward them together with all following non-target parameters
# to the build script
.PHONY: $(TARGETS)
$(TARGETS): ; @./make $(MAKECMDGOALS)

# ignore any non-target parameters if they come after a real
# target.  Without this distinction between target and non-target
# parameters, make would call the build script once per
# commandline parameter.
#
# However, if a non-target parameter comes first on the
# commandline, call the build script to error out on it.
ifneq ($(filter $(word 1, $(MAKECMDGOALS)), $(TARGETS)),)
%: ; @:
else
%: ; @./make $(MAKECMDGOALS)
endif
