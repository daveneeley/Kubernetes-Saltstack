k8s.master.set_master_grain:
  grains.present:
    - name: role
    - value: k8s-master

mine_functions:
  grains.get:
    - fqdn
