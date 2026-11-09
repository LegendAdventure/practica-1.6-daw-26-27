#! /bin/bash
set -ex

./install_lamp.sh
./setup_letsencrypt_certificate.sh
./deploy_wordpress.sh