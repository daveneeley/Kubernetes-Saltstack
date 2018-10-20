base:
  'my-salt-master':
    - k8s.certs.setup
  'my-master-nodes':
    - k8s.master.grain
  'my-worker-nodes':
    - k8s.worker.grain
  'role:k8s-master':
    - match: grain
    - k8s.certs
    - k8s.master
  'role:k8s-worker':
    - match: grain
    - k8s.certs
    - k8s.worker
