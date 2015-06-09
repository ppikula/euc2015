# euc2015

EUC Tutorial: Load testing XMPP servers with Plain Old Erlang

Some of the steps described below are taken from Radek's tutorial:
https://github.com/lavrin/euc-2014/ Thanks Radek!


# Prerequisities

* Vagrant
* Virtualbox
* ansible

# Installing From scratch

Clone this directory:

`git clone https://github.com/ppikula/euc2015.git`

Start virtualbox machine:

`vagrant up`

Log into the machine using

`vagrant ssh`

Run the following command to install docker:

`/vagrant/install_docker.sh`

After that step you need to logout and back otherwise you won't be able to use
docker without sudo.


# Installing from a usb stick

In case you're setting up the environment from a provided USB stick, you'll
still need VirtualBox and Vagrant.

```
git clone https://github.com/ppikula/euc2015
cd euc2015
cp -R /usb-stick-mountpoint/euc2015/.vagrant .
```

Apart from `.vagrant` directory, we will need the VirtualBox VMs. Copy them from
the USB stick to `~/VirtualBox VMs`.  Preferably don't do it from the shell, as this will show no progress indicator.

Once the VMs are copied, let's verify that they start up without errors:

```
cd euc2015
vagrant up
```

Please don't issue vagrant up before the machines are copied! VirtualBox won't
find the machine and Vagrant will try to provision it, overwriting the data in the
`.vagrant` directory.

# Breaking a single box

Start the environment using:

`docker_compose up -d`

`docker ps` should print something like this:

```
ONTAINER ID        IMAGE                         COMMAND                CREATED             STATUS              PORTS                                              NAMES
1bcd9d868913        grafana/grafana:latest        "/usr/sbin/grafana-s   20 seconds ago      Up 19 seconds       0.0.0.0:8081->3000/tcp                             workdir_grafana_1
c75e0ba906dd        workdir_amocmaster:latest     "/opt/run.sh"          4 minutes ago       Up 4 minutes        22/tcp                                             workdir_amocmaster_1
b8d2c52f3a0d        workdir_mim1:latest           "./start.sh"           4 minutes ago       Up 4 minutes        4369/tcp, 5222/tcp, 5269/tcp, 5280/tcp, 9100/tcp   workdir_mim1_1
390306b2bb66        sitespeedio/graphite:latest   "/sbin/my_init"        4 minutes ago       Up 4 minutes        0.0.0.0:2003->2003/tcp, 0.0.0.0:8080->80/tcp       workdir_graphite_1
```

If you open a browser and paste the following adress `http://localhost:9081/` you
will see the grafana log in page. Use admin/admin to log in. Now we have to add a
data source to grafana. The data is going to flow from graphite. Click on the logo
top left corner, you will see Data Sources section. Go there and add a new data source
Name:`graphite` `Url: http://graphite` Access: `proxy`.

Now we are ready to import the dashboard that I've preapared. Click on the "Home"
button and then import select `XMPP....json` file from the euc2015/dashboards directory.
Right now you should be able to see six graphs. So the monitoring is ready to use.

The last step required is to create some use accounts:

```
# enter Mongoose debug shell
docker exec -it workdir_mim1_1 mongooseimctl debug
# use the following snippet
[ejabberd_admin:register(<<"user_", (integer_to_binary(I))/binary>>, <<"localhost">>, <<"password_",(integer_to_binary(I))/binary>>) || I <- lists:seq(1, 1000)].
# exit with C-c C-c
```

We are ready to enter AMOC container with:

`docker exec -it workdir_amocmaster_1 bash`

Now we have to verify the hosts file and setup correct names and options like graphite
ip.


After that we can run:

```
make deploy
/root/amoc_master/bin/amoc
```

Right now  we are in the AMOC "UI" in which we can test our scenarios by running it
on the amocmaster node:

```
amoc_local:do(scenario, 1, 10)  % generate 10 users
amoc_local:add(scenario, 100) % log in 100 more users
amoc_local:remove(scenario, 20) % log out 20 users
```

# Scaling MongooseIM and AMOC

To scale Mongooseim you have to uncomment `mim2` section in the docker-compose.yml file

In case of AMOC you need to uncomment `slave1` and `slave2` in the docker-compose.yml file
and add newly created hosts to the `hosts` file on amocmaster.


To run sceanarios on  slave nodes we need to replace `amoc_local` with `amoc_dist`

```
amoc_dist:do(scenario, 1, 10)  % generate 10 users
amoc_dist:add(scenario, 100) % log in 100 more users
amoc_dist:remove(scenario, 20) % log out 20 users
```

# Add custom metrics

Take a look at `scenarios/mongoose_simple_with_metrics.erl`

# Troubleshooting

### Vagrant can't `ssh` into a virtual machine

Vagrant might sometimes give you a "Connection timeout" error when trying
to bring a machine up or ssh to it.
This is an issue with DHCP and/or VirtualBox DHCP server:

    $ vagrant up
    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Importing base box 'precise64_base'...
    ==> default: Matching MAC address for NAT networking...
    ==> default: Setting the name of the VM: euc-2015_default_1401796905992_8586
    ==> default: Fixed port collision for 22 => 2222. Now on port 2200.
    ==> default: Clearing any previously set network interfaces...
    ==> default: Preparing network interfaces based on configuration...
        default: Adapter 1: nat
        default: Adapter 2: hostonly
    ==> default: Forwarding ports...
        default: 22 => 2200 (adapter 1)
    ==> default: Running 'pre-boot' VM customizations...
    ==> default: Booting VM...
    ==> default: Waiting for machine to boot. This may take a few minutes...
        default: SSH address: 127.0.0.1:2200
        default: SSH username: vagrant
        default: SSH auth method: private key
        default: Warning: Connection timeout. Retrying...
        default: Warning: Connection timeout. Retrying...
        default: Warning: Connection timeout. Retrying...


**Trying again might work**

Issuing `vagrant halt -f <the-machine>` and `vagrant up <the-machine>`
(possibly more than once) might make the machine accessible again.


**Manually reconfiguring will work, but it's troublesome**

If not, then it's necessary to `vagrant halt -f <the-machine>`,
toggle the `v.gui = false` switch in `Vagrantfile` to `v.gui = true`
and `vagrant up <the-machine>` again.

Once the GUI shows up we need to login with `vagrant:vagrant`
and (as `root`) create file `/etc/udev/rules.d/70-persistent-net.rules`
the contents of which must be as follows (one rule per line!):

    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="pcnet32", ATTR{address}=="?*", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="e1000", ATTR{address}=="?*", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth1"

Unfortunately, the GUI doesn't allow for copy-pasting the contents,
so they have to be typed in.
With this file in place, the machine should be SSH-accessible after the
next reboot.


**Destroying and recreating the machine will work, but takes some time**

Alternatively, you might just `vagrant destroy <the-machine>`
and recreate it following the steps from _Setting up the environment_.


**Why does this happen?**

This problem is caused by random ordering of the network devices detected
at guest system boot up.
That is, sometimes Adapter 1 is detected first and gets called `eth0`
while Adapter 2 is `eth1` and sometimes it's the other way around.

Since the guest network configuration is bound to `ethN` identifier,
not to the device itself and the hypervisor network configuration is bound
to adapter number (not the `ethN` identifier),
the situation might sometimes lead to a mismatch:
the guest system tries to use a static address for a VirtualBox NAT adapter
which ought to be configured via DHCP.
This invalid setup leads to SSH failing to establish a connection.
