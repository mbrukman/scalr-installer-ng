#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Prepare the build
cd /builder
 
# Launch build
echo "Building: ${SCALR_VERSION}"
bin/omnibus build scalr-server

cd "${OMNIBUS_PACKAGE_DIR}"
chown "${JENKINS_UID}:${JENKINS_UID}" *

