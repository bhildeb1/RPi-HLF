#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -ex

# clean the keystore
rm -rf ./hfc-key-store

# shut blockchain network down
pushd ../first-network
echo y | ./byfn.sh down
popd
