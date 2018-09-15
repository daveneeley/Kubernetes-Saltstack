/var/lib/kubernetes:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 750

/var/lib/kubernetes/ca.pem:
  file.managed:
    - source:  salt://k8s/certs/ca.pem
    - group: root
    - mode: 644
{% if 'role' in grains and 'k8s-master' in grains['role'] %}
    - watch_in:
      - k8s.master.etcd.etcd
      - k8s.master.kube-apiserver
      - k8s.master.kube-controller-manager
      - k8s.master.kube-scheduler
{% elif 'role' in grains and 'k8s-worker' in grains['role'] %}
    - watch_in:
      - k8s.worker.kubelet
      - k8s.worker.kube-proxy
{% endif %}

/var/lib/kubernetes/ca-key.pem:
  file.managed:
    - source:  salt://k8s/certs/ca-key.pem
    - group: root
    - mode: 600

/var/lib/kubernetes/kubernetes-key.pem:
  file.managed:
    - source:  salt://k8s/certs/kubernetes-key.pem
    - group: root
    - mode: 600
{% if 'role' in grains and 'k8s-master' in grains['role'] %}
    - watch_in:
      - k8s.master.etcd.etcd
      - k8s.master.kube-apiserver
      - k8s.master.kube-controller-manager
      - k8s.master.kube-scheduler
{% elif 'role' in grains and 'k8s-worker' in grains['role'] %}
    - watch_in:
      - k8s.worker.kubelet
      - k8s.worker.kube-proxy
{% endif %}

/var/lib/kubernetes/kubernetes.pem:
  file.managed:
    - source:  salt://k8s/certs/kubernetes.pem
    - group: root
    - mode: 644
{% if 'role' in grains and 'k8s-master' in grains['role'] %}
    - watch_in:
      - k8s.master.etcd.etcd
      - k8s.master.kube-apiserver
      - k8s.master.kube-controller-manager
      - k8s.master.kube-scheduler
{% elif 'role' in grains and 'k8s-worker' in grains['role'] %}
    - watch_in:
      - k8s.worker.kubelet
      - k8s.worker.kube-proxy
{% endif %}

## Token & Auth Policy
/var/lib/kubernetes/token.csv:
  file.managed:
    - source:  salt://k8s/certs/token.csv
    - template: jinja
    - group: root
    - mode: 600
