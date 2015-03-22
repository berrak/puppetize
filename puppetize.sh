#!/bin/bash
#
# Menu script to prepare a host to be puppetized
#

MYIPADDRESS=`ip route get 1 | awk '{print $NF;exit}'`
MYDOMAIN_NAME=`/bin/hostname -d`
MYHOST_NAME=`/bin/hostname`

function gitclient {
    clear
    /usr/bin/apt-cache policy git | /bin/grep -F none
    if ! [ "$?" ]
    then    
        /usr/bin/aptitude install git
    else
        echo -e "\t Git is already installed! Continue with other options."
        read -n 1 myopt
    fi
}


function dnsmasq {
    clear
    /usr/bin/apt-cache policy dnsmasq | /bin/grep -F none
    if [ "$?" ]
    then
        echo -e "\t Installing dnsmasq and utilities ..."
        /usr/bin/aptitude install dnsmasq dnsutils
        
        RESOLVEFILE="/etc/resolv.conf"
        
        NEWNAME=$RESOLVEFILE.`date +%Y%m%d.%H%M.UTC.bak`;
        mv $RESOLVEFILE $NEWNAME;
        echo -e "\t Backed up $RESOLVEFILE to $NEWNAME."; 
        cp -p $NEWNAME $RESOLVEFILE;

        cat << EOF > $RESOLVEFILE
nameserver 127.0.0.1
nameserver 208.67.222.222
nameserver 208.67.220.220
EOF

        echo -e "\t Updated $RESOLVEFILE with new configuration."; 

        DNSMASQ_CONF="/etc/dnsmasq.conf"
        
        NEWNAME=$DNSMASQ_CONF.`date +%Y%m%d.%H%M.UTC.bak`;
        mv $DNSMASQ_CONF $NEWNAME;
        echo -e "\t Backed up $DNSMASQ_CONF to $NEWNAME."; 
        cp -p $NEWNAME $DNSMASQ_CONF;

        cat << EOF > $DNSMASQ_CONF
bogus-priv
server=208.67.222.222
server=208.67.220.220
interface=lo
interface=eth0
listen-address=127.0.0.1
listen-address=${MYIPADDRESS}
bind-interfaces
cache-size=150
log-queries
EOF

        echo -e "\t Updated $DNSMASQ_CONF with new configuration."; 
        echo -e "\t dnsmasq install done ..."
    else
        echo -e "\t dnsmasq is already installed! Continue with other options."
        read -n 1 myopt
    fi
}


function puppet_agent {
    clear
    /usr/bin/apt-cache policy puppet | /bin/grep -F none
    if ! [ "$?" ]
    then

        echo -en "\t Enter the ipaddress in dotted-quad notation to Puppet Master host: "
        read PUPPET_SRV_IPADDR

        # Test if puppet server ipaddress is reachable
        /bin/ping -c $PUPPET_SRV_IPADDR
        if [ "$?" ]
        then

            /usr/bin/apt-cache policy puppetmaster | /bin/grep -F none
            if [ "$?" ]
            then
                echo -e "\t Installing Puppet Agent..."
                /usr/bin/aptitude install puppet facter
                
                HOSTS="/etc/hosts"
                LINE="${PUPPET_SRV_IPADDR}  puppet.${MYDOMAIN_NAME}  puppet\n"
                if ! [ "/bin/grep -Fx '$LINE' '$HOSTS'" ]
                then

                    NEWNAME=$HOSTS.`date +%Y%m%d.%H%M.UTC.bak`;
                    mv $HOSTS $NEWNAME;
                    echo -e "\t Backed up $HOSTS to $NEWNAME."; 
                    cp -p $NEWNAME $HOSTS;
                    
                    echo -e "\t Appending $LINE in $HOSTS to resolve Puppet Master ..."
                    echo $LINE >> $HOSTS
                fi
                
                echo -e "\t Puppet Agent install done ..."
            else
                echo -e "\t This is the Puppetmaster installation! Aborting ..."
                exit 1
            fi

        else
            echo "\nE: Cannot reach given ip address ${PUPPET_SRV_IPADDR}. Aborting ..."
            exit 1
        fi

    else
        echo -e "\t Puppet Agent is already installed! Continue with other options."
        read -n 1 myopt
    fi
    
}

function puppet_master {
    clear
    /usr/bin/apt-cache policy puppetmaster | /bin/grep -F none
    if [ "$?" ]
    then
        echo -e "\t Installing Puppet Master ..."
        /usr/bin/aptitude install puppetmaster

        # Backup original puppet directory files
        echo -e "\t Backup of original puppet files ..."
        cd /etc
        mkdir /etc/puppet.original
        cp -r puppet/* puppet.original/
        
        # Remove before clone
        echo -e "\t Removing content in /etc/puppet ..."
        rm -fr /etc/puppet
        
        echo -e "\t Git cloning new content into /etc/puppet ..."
        git clone https://github.com/berrak/puppet.git puppet
        
        echo -e "\t Copying back original configuration files to /etc/puppet ..."
        cd puppet
        cp ../puppet.original/*.conf .
        
        PUPPET_CONFIG="/etc/puppet/puppet.conf"
        echo -e "\t Updating '$PUPPET_CONFIG' file in /etc/puppet ..."
        
        cat << EOF > $PUPPET_CONFIG
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=/var/lib/puppet/lib/facter
pluginsync=true
server = puppet.${MYDOMAIN_NAME}

[master]
certname = puppet.${MYDOMAIN_NAME}
dns_alt_names = puppet.${MYDOMAIN_NAME},puppet

[agent]
certname = ${MYHOST_NAME}.${MYDOMAIN_NAME}
EOF
        
        echo -e "\t Installing Puppet Agent to manage Puppet Master ..."
        /usr/bin/aptitude install puppet facter
        
        # Update hosts file
        HOSTS="/etc/hosts"
        LINE="${MYIPADDRESS}  puppet.${MYDOMAIN_NAME}  puppet"
        if ! [ "/bin/grep -Fx '$LINE' '$HOSTS'" ]
        then

            NEWNAME=$HOSTS.`date +%Y%m%d.%H%M.UTC.bak`;
            mv $HOSTS $NEWNAME;
            echo -e "\t Backed up $HOSTS to $NEWNAME."; 
            cp -p $NEWNAME $HOSTS;
            
            echo -e "\t Appending $LINE in $HOSTS to resolve Puppet Master ..."
            echo $LINE >> $HOSTS
        fi
        
        echo -e "\t Puppet Master install done ..."
    else
        echo -e "\t Puppet Master is already installed! Continue with other options."
        read -n 1 myopt
    fi

}

function aptitude_update {
    clear
    echo -e "\t Updating APT packaging system ..."
    /usr/bin/aptitude update
    /usr/bin/aptitude safe-upgrade

}

function menu {
    clear
    echo
    echo -e     "\t Admin Debian 8 (Jessie) Puppet Pre-Installer at host '$MYIPADDRESS'\n"
    echo -e     "\t 1. Install Git client (required both for master and agents)"
    echo -e     "\t 2. Install dnsmasq (highly recommended on master)"    
    echo -e     "\t 3. Install Puppet Agent"
    echo -e     "\t 4. Install Puppet Master\n"
    echo -e     "\t 9. Update APT packages\n"    
    echo -e     "\t 0. Exit program\n\n"
    echo -en    "\t Enter option: "
    read -n 1 option
}

if [[ $EUID -ne 0 ]]
then
    echo -e "\nE: You must run script as root or use sudo! Aborting ..." 2>&1
    exit 1
fi

while [ 1 ]
do
    menu
    case $option in
    0)
        break ;;
    1)
        gitclient ;;
    2)
        dnsmasq ;;        
    3)
        puppet_agent ;;
    4)
        puppet_master ;;
    9)
        aptitude_update ;;
        
    *)
        clear
        echo "Sorry, wrong selection" ;;
    esac
    echo -en "\n\t Hit any key continue ..."
    read -n 1 line
done

echo -e "\n\nThank you, terminating script ...\n"


