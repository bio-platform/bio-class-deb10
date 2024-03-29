# Bio-class based on Debian 10 Buster

Repository for building virtual classroom for biology students using [OpenStack](https://cloud.muni.cz/)

* Analysis of gene expression class tought at Institute of Molecular Genetics of the ASCR, v. v. i.
* Genomics: algorithms and analysis class tought at Institute of Molecular Genetics of the ASCR, v. v. i.

## Image with installed software
Use prepared image debian-10-x86_64_bioconductor containing all required software is a preferred way. Some of steps below are covered by [fronted application](http://bio-portal.metacentrum.cz) with guide available [here](doc/user/frontend.md). In case of manual action, please [proceed with all required steps individually](./doc/user/launch-in-personal-project.md).

### SSH Access
Connect to the instance using your [login](https://cloud.gitlab-pages.ics.muni.cz/documentation/cloud/register/), [id_rsa key registered in Openstack](https://cloud.gitlab-pages.ics.muni.cz/documentation/cloud/quick-start/#create-key-pair) or see [Key pair check](./doc/user/launch-in-personal-project.md#key-pair) and [Floating IP in Openstack](https://cloud.gitlab-pages.ics.muni.cz/documentation/cloud/quick-start/#associate-floating-ip) or see [Floating IP check](./doc/user/launch-in-personal-project.md#floating-ip):

* Remove instance host key if previous instance launch using associated *Floating IP*:
```
ssh-keygen -f ~/.ssh/known_hosts -R "<Floating IP>"
```
* Login to the instance using your *login* and associated *Floating IP*:
```
ssh -A -X -i ~/.ssh/id_rsa <login>@<Floating IP>
```
```
-A      Enables forwarding of the authentication agent connection.
-X      Enables X11 forwarding.
```

Password is located at file `/home/<login>/rstudio-pass`.

All required steps are listed in MOTD after login including password.

### First steps after login (NFS, HTTPS and Updates)
First ask your teacher to add your login to the group bioconductor. This is required to access directories.

There are only two steps to proceed with after instance launch using prepared image:
* Start NFS running command `startNFS`
    * Project directory is located under /data/ on your instance and /storage/projects/bioconductor/ on [frontend](https://wiki.metacentrum.cz/wiki/Frontend)
      * There are 2 directories present:
        * /data/persistent - contains home directories for each BIO class user
          * Backup directory of your instance home directory is located under /data/persistent/<your_login>/bio-class-deb10/
        * /data/shared - contains shared data for BIO class
    * In case of issues try to execute `stopNFS` and `startNFS` again
    * To backup you home directory with lesson results to NFS execute `backup2NFS`, to restore `restoreFromNFS`
      * (Nothing is deleted on the other side, add --delete in .bashrc alias if you wish to perform delete during rsync (For Experienced Users Only))
    * After instance reboot execute check `statusNFS`, if issue to list shared data then execute `startNFS` again

* Swith to HTTPS running command `startHTTPS`
    * By default Rstudio uses HTTP (unsecured) and is accesible on port 8787
    * Find out the current Rstudio URL using command `statusHTTPS`
    * In case of issues try to execute `stopHTTPS` and `startHTTPS` again
    * In case of issue obtaing Let's Encrypt certificate using `startHTTPS` try `startHTTPSlocalCrt` (For Experienced Users Only)
      ([In browser you need to accept self-signed certificate](doc/img/browser_exception.png))
    * To switch back to HTTP only use `stopHTTPS`
    * Find out the current Rstudio URL using command `statusHTTPS`

* Update R/Bioconductor packages
    * Execute `statusBIOSW` to see installed/out-of-date packages
    * Execute `updateBIOSW` to update out-of-date packages or execute inside Tmux (if unstable SSH session)
    * Execute `statusBIOSW` to check if any other updates available

* Update OS
  * Backup your home directory to NFS executing `backup2NFS` before updating OS
  * Execute `updateOS` or execute inside Tmux (if unstable SSH session)
  * Please note, that instance may be rebooted immediately after update

* Update repository
  * To obtain latest changes of this repository execute `updateREPO`

* Updates are installed automatically every first Saturday of every month. In case of need to disable the updates completely, execute command `sudo sed -i 's/^/#/g' /etc/cron.d/updates` (For Experienced Users Only, At Your Own Risk)

* Backup home directory to NFS
  * Backup your home directory to NFS executing `backup2NFS`
  * Restore data back to the instance executing `restoreFromNFS` (For Experienced Users Only)
  * Please note that in this Debian 10 version backup directory is located under /data/persistent/<your_login>/bio-class-deb10/

* For security reasons failed login attempt limits are realized, so after exceeding this limit your IP address may be blocked for some time. See more below in section [Fail2ban](#fail2ban). To prevent ban you can insert your public IPv4 addresses (Office/Home/VPN etc) into [Metadata](#unban-your-public-ip).

* Support
  * Send email to [meta@cesnet.cz](mailto:meta@cesnet.cz?subject=Bioconductor), do not forget to mention Bioconductor in Subject field
  * Use Request tracker to [create new ticket](https://rt.cesnet.cz/rt/Ticket/Create.html?Queue=7&Subject=Bioconductor&Content=Issue%20with%20Bioconductor)
    * After login follow the link "klikněte zde pro provedení Vaší žádosti/click here to resume your request"
    * Write down your issue and confirm using button "Vytvořit/Create"
  * #### In your support request please include detailed procedure of your issue with:
    * Login attempt with debug information `ssh -vvv -A -Y -X -i ~/.ssh/id_rsa <login>@<Floating IP>`
    * Existing instances list - [Open Project](https://cloud.muni.cz/) -> Compute -> Instances as printscreen
    * Instance log - [Open Project](https://cloud.muni.cz/) -> Compute -> Instances -> click on instance Name -> submenu *Log* -> button *View Full Log* and attach it as plain text document
    * Instance Overview - [Open Project](https://cloud.muni.cz/) -> Compute -> Instances -> click on instance Name -> submenu Overview -> sections *Specs*, *IP Addresses*, *Security Groups*, *Metadata* or printscreen of this tab
    * Command `statusBIOSW` output and attach it as plain text document

### Tips/FAQ

#### SSH

* If *Are you sure you want to continue connecting (yes/no)?* then confirm using *yes*. Continue only with Enter without *yes* is not enough and login won't be enabled.

Login failed because of using Enter without *yes*
```
# ssh -A -Y -X -i ~/.ssh/id_rsa <login>@<Floating IP>
The authenticity of host '.............' can't be established.
ECDSA key fingerprint is SHA256:..................
Are you sure you want to continue connecting (yes/no)?
Host key verification failed.
```

Correct confirm using *yes* and login
```
# ssh -A -Y -X -i ~/.ssh/id_rsa <login>@<Floating IP>
The authenticity of host '.............' can't be established.
ECDSA key fingerprint is SHA256:..................
Are you sure you want to continue connecting (yes/no)? yes
....
user@instance:~$
```

* If *WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!* then remove known_hosts record from previous instances before connecting from your computer

```
ssh-keygen -f ~/.ssh/known_hosts -R "<Floating IP>"
```

* Verify Passphrase/Public key

Execute command `ssh-keygen -y -f ~/.ssh/id_rsa` and enter passphrase. If correct passphrase, then public key will be shown, otherwise error message.

Correct passphrase with public key in output:
```
ssh-keygen -y -f ~/.ssh/id_rsa
Enter passphrase: *******
ssh-rsa AAAAB3NzaC1yc2EAAAADAQ...............................AAABAQDBJhVYDYxXOvcQ==
```

Incorrect passphrase:
```
ssh-keygen -y -f ~/.ssh/id_rsa
Enter passphrase: *******
Load key "/root/.ssh/id_rsa": incorrect passphrase supplied to decrypt private key
```

On Windows you can use *PutttyGen* (included in [Putty installer](https://www.putty.org)) to verify your *Passphrase/Public key* as descibed at [RELOADING A PRIVATE KEY](https://www.ssh.com/ssh/putty/putty-manuals/0.68/Chapter8.html#puttygen-load).

* Check key fingerprint (md5)

Execute command below to check fingerprint of your key against imported public key in Project->Compute->Keys->key detail

```
ssh-keygen -E md5 -l -f ~/.ssh/id_rsa
2048 MD5:94:c0:ea:94:c0:ea:94:c0:ea:94:c0:ea:94:c0:ea:aa ~/.ssh/id_rsa.pub (RSA)
```

* If *No X11 DISPLAY variable was set, but this program performed an operation which requires it* during fastqc executing then run command below before connecting to instance. Remove known_hosts record from previous instances also.

```
export DISPLAY=localhost:0.0
ssh -A -X -i ~/.ssh/id_rsa <login>@<Floating IP>
```

Test X11 forwarding from instance
```
xclock
xterm
```

#### Rstudio

* If *rstudio Error: Unable to establish connection with R session* or *Unable to establish connection with R session* then restart instance. For example excercise AGE E05 consumes almost all of available memory so reboot before this excercise is good idea.

```
sudo reboot
```

Do not forget do check NFS after reboot, if issue to list shared data then execute `startNFS`
```
statusNFS
startNFS
```

* If you use Shiny library and Shiny do not open then please [confirm pop-ups](doc/img/shiny_pop-ups.png). 

Test Shiny in Rstudio Console

```
library(shiny)
runExample("01_hello")
```

* Show library vignette in Rstudio Console

```
vignette("grid")
vignette("annotate")
```

* Error during plot

Try to resize browser window to increase size of plots pane.
```
Error in plot.new() : figure margins too large
```


#### Conda [Managing packages](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html)

Start Conda
```
startConda
```

List of packages
```
conda list
```

Update Conda
```
conda update conda
```

Search a package
```
conda search cnvkit
```

Install new package
```
conda install scipy
```

Stop Conda
```
stopConda
```

#### Security Groups
In [Security Group add rules](https://cloud.gitlab-pages.ics.muni.cz/documentation/cloud/quick-start/#update-security-group) add rules ([guide here](./doc/user/launch-in-personal-project.md#manage-security-group-rules)):
* For SSH to `<your computer private IPv4 address>/32` or allow it from anywhere `0.0.0.0/0`
* HTTP and HTTPS to allow Ingress availability from anywhere `0.0.0.0/0` (required for generate certificate using response on port 80)
```
Ingress         IPv4    TCP     22 (SSH)        <your private IPv4 address>/32       -       -
Ingress         IPv4    TCP     80 (HTTP)       0.0.0.0/0       -       -
Ingress         IPv4    TCP     443 (HTTPS)     0.0.0.0/0       -       -
Egress	        IPv4 	Any 	Any 	0.0.0.0/0
```

In case of ping do not work add rule:
```
Ingress 	IPv4 	ICMP 	Any 	0.0.0.0/0
```

In case of Rstudio using unsecured HTTP add rule:
```
Ingress 	IPv4 	TCP 	8787 	0.0.0.0/0
```

#### HTTPS certificate check

In case of issue to renew certificate for HTTPS
* Cron job or systemd timer renew your certificates automatically
```
cat /etc/cron.d/certbot
systemctl list-timers | egrep certbot.timer
```
* Check current certificate
```
sudo certbot certificates
```
* Test automatic renewal
```
sudo certbot renew --dry-run
```

#### Fail2ban

In case of blocked SSH access due to exceeded limit of failed login attempts, IP address of your personal computer should be blocked. After a half an hour it should be released again.

You can check blocked IP addresses:

```
sudo iptables -n -L
```

Example from previous command output, where NNN.NNN.NNN.NNN is blocked IP address of your computer:
```
...
Chain f2b-ssh (1 references)
target     prot opt source               destination
REJECT     all  --  NNN.NNN.NNN.NNN      0.0.0.0/0            reject-with icmp-port-unreachable
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
...
```

Get chains list (usable to unban from previous output `Chain f2b-ssh (1 references)`):
```
sudo fail2ban-client status
```

Unban specified chain (in the example below as chains use ssh and sshd), replace NNN.NNN.NNN.NNN with your computer IP address
```
sudo fail2ban-client set ssh unbanip NNN.NNN.NNN.NNN
sudo fail2ban-client set sshd unbanip NNN.NNN.NNN.NNN
```

Unban may be executed from Rstudio Console also:
```
system('sudo fail2ban-client status')
system('sudo iptables -n -L')
system('sudo fail2ban-client set ssh unbanip NNN.NNN.NNN.NNN')
system('sudo fail2ban-client set sshd unbanip NNN.NNN.NNN.NNN')
system('sudo fail2ban-client set nginx-rstudio unbanip NNN.NNN.NNN.NNN')
system('sudo fail2ban-client set nginx-rstudio repeat-offender NNN.NNN.NNN.NNN')
system('sudo fail2ban-client set nginx-rstudio repeat-offender-found NNN.NNN.NNN.NNN')
system('sudo fail2ban-client set nginx-rstudio repeat-offender-pers NNN.NNN.NNN.NNN')
```

##### Unban Your Public Ip
In case of too many failed attempts (anyone from your subnet behind public IP address) insert your home computer public IPv4 into instance Metadata. You can change once inserted address at any time again.

* [Open Project](https://cloud.muni.cz/) -> Compute -> Instances and use button on the right of your instance
* Click on down arrow and select Update Metadata
* In Metada dialog insert new variable *Bioclass_ipv4* containing your public IPv4 address (see for example at [What Is My Public IP Address?](https://www.whatismyip.com)) or edit existing variable to a new value
  * Multiple addresses may be inserted with comma as delimiter e.g. `101.101.101.101,102.102.102.102/32,103.103.103.0/24`
  * To remove variable with addresses use button *-* on the right
  * Check variable Bioclass_ipv4 in [Project](https://cloud.muni.cz/) -> Compute -> Instances -> click on Instance name -> tab Overview -> section Metadata
* Proceed with **Save** button
* Wait for approximately 10 minutes until your IP address is inserted into Fail2Ban configuration and service has to be restarted
![Update Metadata](./doc/img/instance_metadata_public_ipv4.png)

If more Bans during 24 hours, then whole access should be blocked for 24 hours!
If more failing SSH attempts during `7*24` hours, then whole access should be blocked for `7*24` hours!

#### Tmux
*  You may open Tmux session using `tmux` or attach to the existing Tmux session by `tmux attach`. Tmux can prevent updates break if your local computer for example loose connection. Another example is executing bash commands with long run time
* Execute command, for example `updateBIOSW` to update installed R/Bioconductor packages or `updateOS` to install OS updates
* You can leave Tmux session now `Ctl+B D` (not closing the session using `Ctrl+D`), because commands can continue in Tmux without your SSH connection active
* Check if command has finished by attaching Tmux session using `tmux attach`, checking output and close Tmux session using `Ctrl+D` if updates/command has finished already


## Admin section
* For testing purposes in case of modifications you may [install all required software directly during VM initialize](doc/admin/test-in-personal-project.md) (time consuming).
* Packer Master VM for buiding images is described [here](doc/admin/packer-image.md#initialize-image-using-prepared-vm-with-packer-installed).
* Note [admin documentation](./doc/admin/).

