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
The iso provided from the `IMAGE_URI` environment variable must be in the directory structure as in
`${IMAGE_URI}/${DISTRIBUTION}-qemu/${DISTRIBUTION}.qcow2` for all builds from this
repository except for building base images which have mirrors set.

The images can be pulled from the [named docker volume](#get-built-images)

The [terminal](./terminal/main.json) image is only supported for debian and
allows live booting over pxe. This requires serving exported files by
packer(the kernel, initrd and squashfs) over http and setting the kernel parameters 
`boot=live fetch=http://<url>/terminal/debian-11.0-amd64-qemu/debian-11.0-amd64.squashfs`


### Building debian images

Export the distribution to build 

    $ export DISTRIBUTION="debian-11.4-amd64"


Build the debian base image.

    $ PACKER_DIRECTORY="base/debian" IMAGE_URI="" bash main.sh packer


Build cloud image based on the new base image

    $ PACKER_DIRECTORY="cloud" IMAGE_URI="/output/base/debian" bash main.sh packer


Build an image for kitchen based on the new base image

    $ PACKER_DIRECTORY="kitchen" IMAGE_URI="/output/base/debian" bash main.sh packer


Build kubernetes image based on the new cloud image

    $ PACKER_DIRECTORY="kubernetes" IMAGE_URI="/output/cloud" bash main.sh packer


Build salt image based on the cloud image

    $ PACKER_DIRECTORY=salt IMAGE_URI="/output" PARENT_IMAGE_TYPE=cloud bash main.sh packer


Build salt image based on debian base image with a different upstream url and version for saltstack

    $ PACKER_DIRECTORY=salt IMAGE_URI="/output" PARENT_IMAGE_TYPE=base/debian SALT_GIT_URL=https://upstream/saltstack/salt.git SALT_VERSION_TAG=v3004.1 bash main.sh packer


#### Example without wrappers

Build the debian base image without docker and entrypoints main.sh, justfile.

    $ export DISTRIBUTION="debian-11.4-amd64" PACKER_DIRECTORY="base/debian" IMAGE_URI="" BUILD_DIRECTORY="./output"
    $ packer build -except=upload -only=qemu -var-file=./files/common.json -var-file=./base/debian/vars/debian-11.4-amd64.json -var-file=./base/debian/vars/common.json  ./base/debian/main.json


### Building archlinux images

Export the distribution to build 

    $ export DISTRIBUTION=archlinux


Build the archlinux base image

    $ PACKER_DIRECTORY="base/arch" IMAGE_URI="" bash main.sh packer


Repeat the same steps as with debian by setting the required PACKER_DIRECTORY and IMAGE_URI environment variables

Build cloud image based on the new base image

    $ PACKER_DIRECTORY=cloud IMAGE_URI="/output/base/arch" bash main.sh packer


## Get built images


List available images

    $ bash main.sh list


Pull image from volume

    $ bash main.sh cat '<absolute filename>' | tar -xf - -C <output path>


## Notes

* make sure to disable or remove the packer user for ssh login with sudo permissions 'provision:provision'(user:password)
* the user provision expires after 35 days - you will need to rebuild a dependant base image if used for building other images by packer
