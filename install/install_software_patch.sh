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
if [[ -f ${CONF_DIR}/nginx-rstudio.conf ]] && [[ -f ${CONF_DIR}/jail.local ]];then
  echo "Going to copy updated nginx-rstudio.conf and jail.local"
  cp ${CONF_DIR}/jail.local /etc/fail2ban
  cp ${CONF_DIR}/nginx-rstudio.conf /etc/fail2ban/filter.d
  for file in /etc/fail2ban/filter.d/nginx-rstudio.conf /etc/fail2ban/jail.local ; do \
  chown root: $file ; \
  chmod 644 $file ; done
  service fail2ban restart
fi

# Ignoreip for fail2ban
BIOSW_IPV4=$(curl -s  http://169.254.169.254/openstack/2016-06-30/meta_data.json 2>/dev/null | python -m json.tool | egrep -i Bioclass_ipv4 |cut -f 2 -d ':' | tr -d ' ' | sed -rn "s/.*\"(.*)\".*/\1/p"| tr '[:upper:]' '[:lower:]' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
tmp_ipv4_jail_local=$(egrep $BIOSW_IPV4 /etc/fail2ban/jail.local)
echo "BIOSW_IPV4: $BIOSW_IPV4"
echo "tmp_ipv4_jail_local: $tmp_ipv4_jail_local"
if [[ -n "$BIOSW_IPV4" ]] && [[ -f /etc/fail2ban/jail.local ]] && [[ -z "$tmp_ipv4_jail_local" ]];then
  echo "Inserting $BIOSW_IPV4 into Fail2ban ignoreip"
  sed -i '/ignoreip/s/$/ '"$BIOSW_IPV4"'/' /etc/fail2ban/jail.local
  service fail2ban restart
fi

#Fix: nfs issue #852196
tmp_nfs_clientid_conf=$(sed -rn "s/^options nfs nfs4_unique_id=(.*)$/\1/p" /etc/modprobe.d/nfs_clientid.conf)
if [[ ! -f /etc/modprobe.d/nfs_clientid.conf ]] || [[ -z "$tmp_nfs_clientid_conf" ]];then
  tmp_uuid=$(curl -s  http://169.254.169.254/openstack/2016-06-30/meta_data.json 2>/dev/null | python -m json.tool | egrep "uuid" |cut -f 2 -d ':' | tr -d ' ' | tr -d '"'| tr -d ',')
  echo "Openstack instance uuid: $tmp_uuid"
  if [[ -z "$tmp_uuid=" ]] ;then
    apt-get -y install uuid-runtime
    tmp_uuid=$(uuidgen)
    echo "Uuidgen uuid: $tmp_uuid"
  fi
  if [[ -n "$tmp_uuid" ]] ;then
    echo "Set $tmp_uuid to /etc/modprobe.d/nfs_clientid.conf"
    echo -e "options nfs nfs4_unique_id=${tmp_uuid}" >  /etc/modprobe.d/nfs_clientid.conf
    chown root: /etc/modprobe.d/nfs_clientid.conf
    chmod 644 /etc/modprobe.d/nfs_clientid.conf
    umount -f /data
    rmmod nfsv4
    rmmod nfs
    modprobe nfs
    mount /data
  fi
fi

# Patch
echo "Install patch has finished"

# Print user to check in log
echo "BIOUSER: $BIOUSER"

exit 0
