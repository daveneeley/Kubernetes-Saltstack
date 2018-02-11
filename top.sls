base:
  'role:k8s-master':
    - match: grain
    - k8s.certs
    - k8s.master
  'role:k8s-worker':
    - match: grain
    - k8s.certs
    - k8s.worker
