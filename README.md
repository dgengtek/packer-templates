# Packer images built with qemu

This repository contains configurations for building arch and debian from installation media provided from the distributions. 

## Requirements

See the [dockerfile](Dockerfile)


Build the docker image for the required dependencies to build the images via packer

    $ bash main.sh docker



## Building images
The iso provided from the `IMAGE_URI` environment variable must be in the directory structure as in
`${IMAGE_URI}/${DISTRIBUTION}-qemu/${DISTRIBUTION}.qcow2` for all builds from this
repository except for building base images which have mirrors set.

The images can be pulled from the [named docker volume](#get-built-images)

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
