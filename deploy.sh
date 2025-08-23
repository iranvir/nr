#!/bin/sh
set -e
mkdocs build
ssh root@www.numbersandreality.com rm -rf /usr/share/nginx/
rsync site -avz root@www.numbersandreality.com:/usr/share/nginx
