#!/bin/bash
set -o errexit
set -o nounset

dpkg -i "${OMNIBUS_PACKAGE_DIR}"
