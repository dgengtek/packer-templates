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

    $ export DISTRIBUTION="debian-11.1-amd64"


Build the debian base image.

    $ PACKER_DIRECTORY="base/debian" IMAGE_URI="" bash main.sh packer


Build cloud image based on the new base image

    $ PACKER_DIRECTORY="cloud" IMAGE_URI="/output/base/debian" bash main.sh packer


Build kubernetes image based on the new cloud image

    $ PACKER_DIRECTORY="kubernetes" IMAGE_URI="/output/cloud" bash main.sh packer


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

    $ bash main.sh images


Pull image from volume

    $ bash main.sh get_image <absolute filename>
