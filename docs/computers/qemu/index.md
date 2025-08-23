# Virtual Labs

QEMU is a huge project with tonnes of different concepts, tools and methods to
work with. This section of this site is dedicated to document and understand a
very small subset of QEMU that interests me.

## Goal
Have a sandbox within which we can make interconnected machines, DNS, DHCPD, etc
so as to emulate a standard enterprise network.

This framework of scripts will allow students, security researcher, etc to get
quickly started.


## Prerequistes
1. Linux Host with x64 architecture
2. `qemu-system-x86_64` package installed either by compiling from source or
   from your distro's package manager. Depending on the distro use: `apk add
   qemu-system-x86_64` or `dnf install qemu-kvm` or `apt install qemu-kvm`. The
    binary is `/usr/bin/qemu-system-x86_64` or `/usr/libexec/qemu-kvm` so modify
   the below scripts accordingly.
3. Install `iproute2`, `iptables` and `qemu-img` using the same steps as above.

## Overview
With the prerequistes met, we can begin creating a virtual machine with the followng components:

1. Create virtual hard disk
2. Create virtual NAT with a subnet
3. Create a virtual machine and install OS in it

## 1. Create a virtual hard disk

We will stick to `.raw` format.

```sh
qemu-img create -f raw -o preallocation=off vmname.raw 8G
```
## 2. Create a virtual NAT

We will create a NAT using the following steps:

Make sure the proper kernal parameters are set and proper kernel modules are
loaded.

```sh
sysctl -w net.ipv4.ip_forward=1
modprobe br_netfilter
modprobe bridge
```

Next, we create a bridge interface. This may sound a bit confusing but we are
not bridging the VM to the local network of our host computer. Instead, this
bridge network is used to provide connectivity to a NAT network of VMs, kinda
like how your home router has one public IP and every device that connects to it
gets a private NAT network.

```sh
ip link add name br0 type bridge
ip link set br0 up
ip addr add 10.0.0.1/24 dev br0
```
Next we create another virtual interface. This is the one that will be "plugged
into" the VM so to speak:

```sh
ip tuntap add mode tap tap0
ip link set tap0 master br0
ip link set tap0 up
```

And finally we set iptables rules to allow this NAT-ed networked to have
internet connectivity to the rest of the world (again in a way which is similar
to how your home router works).

I used `eth0` in the commands, but use the name of the network interface that is
being used by your computer (`ip a` command will help you with this)

```sh
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -j RETURN
```
