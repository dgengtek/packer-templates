{% if config_get("user.network-config", "") == "" %}version: 1
config:
  - type: physical
    name: {% if instance.type == "virtual-machine" %}enp5s0{% else %}eth0{% endif %}
    subnets:
      - type: {% if config_get("user.network_mode", "") == "link-local" %}manual{% else %}dhcp{% endif %}
        control: auto{% else %}{{ config_get("user.network-config", "") }}{% endif %}
