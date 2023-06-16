# Packer images built with qemu

This repository contains configurations for building arch and debian from installation media provided from the distributions.

## Requirements

* docker
  * if building without a docker container see the [dockerfile](Dockerfile)
* [X86_virtualization](https://en.wikipedia.org/wiki/X86_virtualization)
* [kvm](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine) bound on /dev/kvm


Build the docker image for the required dependencies to build the images via packer

    $ bash main.sh docker


## Building images
The images can be pulled from the [named docker volume](#get-built-images)

The [terminal](./terminal/main.json) image is only supported for debian and
allows live booting over pxe. This requires serving exported files by
packer(the kernel, initrd and squashfs) over http and setting the kernel parameters
`boot=live fetch=<http url to squashfs>`


### Building debian images

Build the debian base image.

    $ PKR_VAR_distribution=debian-11.6-adm64 packer build -var-file base/debian/vars/common.json -var-file base/debian/vars/${PKR_VAR_distribution}.json base/debian/
    #
    # or build inside docker
    $ bash main.sh debian base


Build cloud image based on the new base image

    $ PKR_VAR_distribution=debian-11.6-adm64 packer build cloud
    #
    # or build inside docker
    $ bash main.sh debian cloud


Build an image for kitchen based on the new base image

    $ PKR_VAR_distribution=debian-11.6-adm64 packer build kitchen
    #
    # or build inside docker
    $ bash main.sh debian kitchen


Build salt image based on the cloud image

    $ PKR_VAR_distribution=debian-11.6-adm64 packer build -var parent_image_type=cloud salt
    #
    # or build inside docker
    $ bash main.sh debian salt cloud


### Building archlinux images


Build the archlinux base image

    $ PKR_VAR_distribution=archlinux-x86-64 packer build -var-file base/archlinux/vars/common.json -var-file base/archlinux/vars/${PKR_VAR_distribution}.json base/archlinux/
    # or
    $ bash main.sh arch base


Repeat the same steps as with debian

Build cloud image based on the new base image

    $ PKR_VAR_distribution=archlinux-x86-64 packer build cloud
    # or
    $ bash main.sh arch cloud


## Get built images


List available images

    $ bash main.sh list


Pull image from volume

    $ bash main.sh cat '<absolute filename>' | tar -xf - -C <output path>


## Further options

See [common variables](./files/common.pkr.hcl) which can be set and given as arguments to either the `packer -var ... ` command or to  `bash main.sh <arch|debian> <build_type> -var ...`

## Notes

* make sure to disable or remove the packer user for ssh login with sudo permissions 'provision:provision'(user:password)
* the user provision expires after 35 days - you will need to rebuild a dependant base image if used for building other images by packer
