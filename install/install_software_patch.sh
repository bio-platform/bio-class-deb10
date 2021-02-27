#!/bin/bash
# Install patch if difference betweenprepared image/upstream repository versions
PATH=$PATH;PATH+=":/bin" ;PATH+=":/usr/bin";PATH+=":/usr/sbin";PATH+=":/usr/local/bin";
dirname=$(dirname $0)
cd "$dirname"
SCRIPTDIR=$(pwd)
dirname=$(dirname pwd)
PATH+=":$dirname"
export PATH

CONF_DIR="$dirname"/../conf
LIB_DIR="$dirname"/../lib

BIOUSER=$(curl -s  http://169.254.169.254/openstack/2016-06-30/meta_data.json 2>/dev/null | python -m json.tool | egrep -i Bioclass_user |cut -f 2 -d ':' | tr -d ' ' | sed -rn "s/.*\"(.*)\".*/\1/p"| tr '[:upper:]' '[:lower:]')
if [[ -z "$BIOUSER" ]]; then
  echo "Empty Bioclass_user from METADATA, exiting!"
  exit 1
fi

echo "Install patch if needed"

# Patch

tmp_installed=$(apt list --installed 2>/dev/null| egrep -v "^WARNING"| grep "libpng++-dev" | egrep -i "installed")
if [[ -z "$tmp_installed" ]];then
  #libpng++-dev
  apt-get -y install libpng++-dev
fi

# fail2ban
if [[ -f ${CONF_DIR}/nginx-rstudio.conf ]];then
  cp ${CONF_DIR}/nginx-rstudio.conf /etc/fail2ban/filter.d
  for file in /etc/fail2ban/filter.d/nginx-rstudio.conf ; do \
  chown root: $file ; \
  chmod 644 $file ; done
  service fail2ban restart
fi

# Patch
echo "Install patch has finished"

# Print user to check in log
echo "BIOUSER: $BIOUSER"

exit 0
