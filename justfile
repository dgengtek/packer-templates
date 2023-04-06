export PACKER_DIRECTORY := env_var("PACKER_DIRECTORY")
export PACKER_CACHE_DIR := env_var_or_default("PACKER_CACHE_DIR", "./packer_cache")
export http_proxy := env_var_or_default("http_proxy", "")
export https_proxy := env_var_or_default("https_proxy", "")
export no_proxy := env_var_or_default("no_proxy", "")
export DISTRIBUTION := env_var("DISTRIBUTION")
export BUILD_DIRECTORY := if env_var_or_default("BUILD_DIRECTORY", "") == "" { "output" } else { env_var("BUILD_DIRECTORY") + "/" + PACKER_DIRECTORY }
export IMAGE_URI := env_var("IMAGE_URI")
export ENABLE_PKI_INSTALL := env_var_or_default("ENABLE_PKI_INSTALL", "false")


packer_main := PACKER_DIRECTORY + "/main.json"
common_var_file := "./files/common.json"
var_file := `fd --type f --exclude 'common.json' '.json' ./files | fzf -m --prompt='var_file> '`
extended_common := PACKER_DIRECTORY + "/vars/common.json"
var_overrides_file := "/tmp/packer-var_overrides.json"


default:
	@just --list


setup: 
        test -f {{var_overrides_file}} || echo '{}' > {{var_overrides_file}} 
        {{PACKER_DIRECTORY}}/init.sh {{var_overrides_file}}

# validate packer packer_main
check:  setup
	packer validate -var-file={{common_var_file}} -var-file={{extended_common}} -var-file="{{var_file}}" -var-file={{var_overrides_file}} "{{packer_main}}"


# build all from packer_main
build: setup
	packer build -var-file={{common_var_file}} -var-file={{extended_common}} -var-file="{{var_file}}" -var-file={{var_overrides_file}} "{{packer_main}}"


# build only from variable {{provider}}
only provider: setup
	packer build -only={{provider}} -var-file={{common_var_file}} -var-file={{extended_common}} -var-file="{{var_file}}" -var-file={{var_overrides_file}} "{{packer_main}}"


# build with docker, ignore upload
docker *FLAGS: setup
	packer build -except=upload -only=qemu -var-file={{common_var_file}} -var-file={{extended_common}} -var-file={{var_file}} -var-file={{var_overrides_file}} {{FLAGS}} {{packer_main}}
