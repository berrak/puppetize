## A Puppet Pre-Install Shell Script for Debian 8 (Jessie)

This shell script automates the pre-configuration both for Puppet Master and Agents.

This script have been used on Debian 8 (Jessie) hosts. Other distributions may work
but that is not tested. 

Download/clone the script and make the script executable with:

    $ sudo chmod u+x ./puppetize.sh

Simply run the script like so:

    $ sudo ./puppetize.sh

or run as root:

    # ./puppetize.sh
    

This opens a menu screen that may look like so:

<pre>

    Admin Debian 8 (Jessie) Puppet Pre-Installer at host '192.168.0.222'

    1. Install Git client (required both for master and agents)
    2. Install dnsmasq (highly recommended on master)
    3. Install Puppet Agent
    4. Install Puppet Master

    9. Update APT packages

    0. Exit program


    Enter option: 

</pre>


### Sign Puppet Master

If required, to recreate any certificates for Puppet Master, stopp and start the service again.

    # /etc/init.d/puppetmaster stop
    # /etc/init.d/puppetmaster start 

or use:

    # systemctl stop puppetmaster
    # systemctl start puppetmaster
    
    
### Sign Puppet Agents (including on Master itself)
    
On Puppet Master (in this case), create a node certificate:

    # puppet agent --onetime --no-daemonize --verbose --waitforcert 60
    
In the second root terminal login to view and sign the request from this request with:

    # puppet cert --list
    # puppet cert --sign <node-name>
    

### Shell Script Assumptions

Currently, the script assumes that DNS resolves using OpenDNS public ipaddresses and the primary
network interface is *eth0* when *dnsmasq* is configured in that menu option.

