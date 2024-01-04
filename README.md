# Packer images built with qemu

This repository contains configurations for building archlinux and debian from installation media provided from the distributions.

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

Export the required environment variable

    $ export PKR_VAR_distribution=debian-12.4.0-amd64


Build the debian base image.

    $ packer build -var-file base/debian/vars/common.json -var-file base/debian/vars/${PKR_VAR_distribution}.json base/debian/
    #
    # or build inside docker
    $ bash main.sh debian base


Build cloud image based on the new base image

    $ packer build cloud
    #
    # or build inside docker
    $ bash main.sh debian cloud


Build an image for kitchen based on the new base image

    $ packer build kitchen
    #
    # or build inside docker
    $ bash main.sh debian kitchen


Build salt image based on the cloud image

    $ packer build -var parent_image_type=cloud salt
    #
    # or build inside docker
    $ bash main.sh debian salt cloud


### Building archlinux images

Export the required environment variable

    $ export PKR_VAR_distribution=archlinux-x86-64


Build the archlinux base image

    $ packer build -var-file base/archlinux/vars/common.json -var-file base/archlinux/vars/${PKR_VAR_distribution}.json base/archlinux/
    # or
    $ bash main.sh archlinux base


Repeat the same steps as with debian

Build cloud image based on the new base image

    $ packer build cloud
    # or
    $ bash main.sh archlinux cloud


## Building uefi images

When using the wrapper without setting any environment variables it will use the OVMF from the docker image

    $ bash main.sh --uefi debian base

Export the required efi environment variables if you want to build without packer or want to provide your own OVMF which will be mounted into the docker container

    $ export PKR_VAR_efi_firmware_code=<path to OVMF_CODE> PKR_VAR_efi_firmware_vars=<path to OVMF_VARS>
    $ packer build ...


## Get built images


List available images

    $ bash main.sh list


Pull image from volume

    $ bash main.sh cat '<absolute filename>' | tar -xf - -C <output path>


## Further options

See [common variables](./files/common.pkr.hcl) which can be set and given as arguments to either the `packer -var ... ` command or to  `bash main.sh <archlinux|debian> <build_type> -var ...`

## Notes

* make sure to disable or remove the packer user for ssh login with sudo permissions 'provision:provision'(user:password)
* the user provision expires after 35 days - you will need to rebuild a dependant base image if used for building other images by packer
