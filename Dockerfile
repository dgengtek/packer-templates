ARG dockerfile_from_image=debian:bookworm-slim
FROM ${dockerfile_from_image} as tmp

ARG packer_version=1.9.1

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y unzip \
  && curl -L -o packer.zip "https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip" \
  && curl -L -o fd.tar.gz 'https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-unknown-linux-gnu.tar.gz' \
  && unzip packer.zip \
  && tar --strip-components=1 -xzf fd.tar.gz

FROM ${dockerfile_from_image} as build

ENV BUILD_DIRECTORY=/output
ENV efi_firmware_code=/usr/share/OVMF/OVMF_CODE.fd
ENV efi_firmware_vars=/usr/share/OVMF/OVMF_VARS.fd

COPY --from=0 /packer /bin/packer
COPY --from=0 /fd /bin/fd
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y qemu-system-x86 qemu-utils ovmf fzf git ansible jq \
  && mkdir $BUILD_DIRECTORY


WORKDIR /wd

VOLUME $BUILD_DIRECTORY

ENTRYPOINT ["/bin/bash"]
