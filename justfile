export PACKER_DIRECTORY := env_var("PACKER_DIRECTORY")
export DISTRIBUTION := env_var("DISTRIBUTION")
export BUILD_DIRECTORY := if env_var_or_default("BUILD_DIRECTORY", "") == "" { "output" } else { env_var("BUILD_DIRECTORY") + "/" + PACKER_DIRECTORY }
export IMAGE_URI := env_var("IMAGE_URI")


packer_main := PACKER_DIRECTORY + "/main.json"
common_var_file := "./files/common.json"
var_file := `fd --type f --exclude 'common.json' '.json' ./files | fzf -m --prompt='var_file> '`
extended_common := PACKER_DIRECTORY + "/vars/common.json"


default:
	@just --list


setup: 
        -{{PACKER_DIRECTORY}}/init.sh

# validate packer packer_main
check:  setup
	packer validate -var-file={{common_var_file}} -var-file="{{var_file}}" -var-file={{extended_common}} "{{packer_main}}"


# build all from packer_main
build: setup
	packer build -var-file={{common_var_file}} -var-file="{{var_file}}" -var-file={{extended_common}} "{{packer_main}}"


# build only from variable {{provider}}
only provider: setup
	packer build -var-file={{common_var_file}} -only={{provider}} -var-file="{{var_file}}" -var-file={{extended_common}} "{{packer_main}}"


lxd profile: setup
	packer build -only=lxd -var-file={{common_var_file}} -var-file="{{var_file}}" -var 'profile={{profile}}' -var-file={{extended_common}} "{{packer_main}}"


# build with docker, ignore upload
docker: setup
	packer build -except=upload -only=qemu -var-file={{common_var_file}} -var-file={{var_file}} -var-file={{extended_common}} {{packer_main}}
