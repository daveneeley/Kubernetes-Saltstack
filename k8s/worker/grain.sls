k8s.worker.set_worker_grain:
  grains.present:
    - name: role
    - value: k8s-worker

mine_functions:
  grains.get:
    - fqdn
