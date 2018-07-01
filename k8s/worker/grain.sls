k8s.worker.set_worker_grain:
  grains.present:
    - name: role
    - value: k8s-worker

mine_functions:
  k8s-node-list:
    - mine_function: grains.get
    - fqdn
