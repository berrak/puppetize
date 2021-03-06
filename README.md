## A Puppet Pre-Install Shell Script for Debian 8 (Jessie)

This shell script automates the pre-configuration both for Puppet Master and Agents.
This script have been used on Debian 8 (Jessie) hosts. Other distributions may work
but that's not yet tested. 

The target machine initial state is a working install from Debian media or from a
net-install. For additional information, see Debian official site of all releases:

https://wiki.debian.org/DebianReleases
   
### Setup   
    
Login to target host and install git: 

    # aptitude install git
    
Clone the repository as an unpriveleged user:

    # su <user>
    $ cd ~    
    $ git clone https://github.com/berrak/puppetize.git
    $ cd puppetize
    
Ensure script is executable and run like so:

    $ su -c './puppetize.sh'
    Password: *********
    

### How to use it

This opens a menu screen that may look like so:

<pre>

    Admin Debian 8 (Jessie) Puppet Pre-Installer at host '192.168.0.222' (eth0)

    1. Install Git client (required both for master and agents)
    2. Install dnsmasq (highly recommended on master)
    3. Install Puppet Agent
    4. Install Puppet Master

    9. Update APT packages

    0. Exit program


    Enter option: 

</pre>


For *Puppet Agent* select 9, 1, and 3.

For *Puppet Master* select 9, 1, 2, and 4.
Use the highly recommended option *dnsmasq* for *Puppet Master*.


### What is automated

Following actions are automated, depending on what options are selected.

When selecting *Puppet Agent* on the menu, following happens: 

    - Installs 'puppet' and 'facter'
    - Updates '/etc/hosts' file - prompts for IPv4 address to 'Puppet Master'

When selecting *Puppet Master* on the menu, following happens:


    - Installs 'puppetmaster'
    - Clones 'https://github.com/berrak/puppet.git' - Debian install is replaced
    - Configures a new 'puppet.conf'
    - Configures a basic 'hiera.yaml' file
    - Installs 'puppet' agent and 'facter' (Puppet Master machine is managed)
    - Updates '/etc/hosts' file
    
The machine *hosts* file and the Debian default puppet configuration files are backed up.


### Sign Puppet Master

If required, to re-create any certificates for Puppet Master, stop and start the service again.

    # /etc/init.d/puppetmaster stop
    # /etc/init.d/puppetmaster start 

or use *systemctl* like so:

    # systemctl stop puppetmaster
    # systemctl start puppetmaster
    
    
### Node Signature Process (including on Puppet Master itself)
    
On Puppet Master (in this case), create a node certificate:

    # puppet agent --onetime --no-daemonize --verbose --waitforcert 60
    
In the second root terminal, login to view and sign the request from this request with:

    # puppet cert list --all
    # puppet cert sign <node-name>
    
The first run on a new machine will not run. Enable *Puppet Agent* with:

    # puppet agent --enable
    
Re-run *Puppet Agent*:
    
    # puppet agent --onetime --no-daemonize --verbose


### Certificate Troubles

In case of certification issues, first remove them completely and then re-create
with a *Puppet Master* re-start cycle. 

    # cd /var/lib/puppet
    # rm -fr ssl
    
The last command will wipe all old certificates from puppet store, which can be verified by:

    # puppet cert list --all
    # /etc/init.d/puppetmaster stop
    # /etc/init.d/puppetmaster start
    # puppet cert list --all  

The last command shows the new *Puppet Master* certificates. Add new node certificates
for all *Puppet Agents* with the node signature process above.


### Shell Script Assumptions

Currently, the script assumes that DNS resolves using *OpenDNS* public ipaddresses.
These are hard coded in the script in the *dnsmasq* menu section.

