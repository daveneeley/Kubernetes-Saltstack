k8s.master.firewall.kubernetes:
  firewalld.service:
    - name: kubernetes
    - ports:
      - 6443/tcp
