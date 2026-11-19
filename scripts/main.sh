#!/bin/bash
set -ex

./install_lamp.sh
./setup_letsencrypt_https.sh
./deploy.sh