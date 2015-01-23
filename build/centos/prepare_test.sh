#!/bin/bash
set -o errexit
set -o nounset

yum install "${OMNIBUS_PACKAGE_DIR}"
