ARG dockerfile_from_image=debian:bullseye-slim
FROM ${dockerfile_from_image} as tmp

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y unzip \
  && curl -L -o packer.zip 'https://releases.hashicorp.com/packer/1.7.8/packer_1.7.8_linux_amd64.zip' \
  && curl -L -o fd.tar.gz 'https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-unknown-linux-gnu.tar.gz' \
  && unzip packer.zip \
  && tar --strip-components=1 -xzf fd.tar.gz

FROM ${dockerfile_from_image} as build

ENV BUILD_DIRECTORY=/output

COPY --from=0 /packer /bin/packer
COPY --from=0 /fd /bin/fd
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y qemu-system-x86 qemu-utils fzf git ansible jq \
  && mkdir /output /wd

WORKDIR /wd

VOLUME $BUILD_DIRECTORY

ENTRYPOINT ["/bin/bash"]
