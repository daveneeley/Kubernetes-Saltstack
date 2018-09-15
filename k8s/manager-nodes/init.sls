{% from 'ks8/map.jinja' import k8s with context %}
setup-srv-k8s:
  file.directory:
    - name: /srv/k8s
    - makedirs: True

download-k8s-manager-node-configs:
  file.recurse:
    - name: /srv/k8s
    - source: salt://k8s/manager-nodes
    - template: jinja
    - defaults:
        CLUSTER_DOMAIN: {{ pillar['kubernetes']('domain') }}
        MASTER_HOSTNAME: {{ pillar['kubernetes']('master:hostname') }}
        CPU_ARCH_MAP: {{ k8s.cpu_arch_map }}

create-k8s-rbac-calico:
  cmd.run:
    - name: kubectl create -f rbac-calico.yaml
    - cwd: /srv/k8s

create-k8s-policy-controller:
  cmd.run:
    - name: kubectl create -f /opt/calico.yaml && sleep 10
    - cwd: /srv/k8s

{#
create-k8s-kube-dns:
  cmd.run:
    - name: kubectl create -f kube-dns.yaml
    - cwd: /srv/k8s
#}

create-k8s-coredns:
  cmd.run:
    - name: kubectl create -f coredns.yaml
    - cwd: /srv/k8s

create-k8s-kubernetes-dashboard:
  cmd.run:
    - name: kubectl create -f kubernetes-dashboard.yaml
    - cwd: /srv/k8s

create-k8s-heapster-rbac:
  cmd.run:
    - name: kubectl create -f heapster-rbac.yaml
    - cwd: /srv/k8s

create-k8s-influxdb:
  cmd.run:
    - name: kubectl create -f influxdb.yaml
    - cwd: /srv/k8s

create-k8s-grafana:
  cmd.run:
    - name: kubectl create -f grafana.yaml
    - cwd: /srv/k8s

create-k8s-heapster:
  cmd.run:
    - name: kubectl create -f heapster.yaml
    - cwd: /srv/k8s

download-k8s-helm:
  archive.extracted:
    - name: /srv/k8s
    - source: https://kubernetes-helm.storage.googleapis.com/helm-{{ pillar['kubernetes']('global:helm-version') }}-linux-{{ k8s.cpu_arch_map }}.tar.gz

manage-k8s-helm:
  file.managed:
    - name: /usr/local/bin/helm
    - source: /srv/k8s/linux-{{ k8s.cpu_arch_map }}/helm
    - file_mode: 755

create-k8s-service-account-tiller:
  cmd.run:
    - name: kubectl create serviceaccount tiller --namespace kube-system
    - cwd: /srv/k8s

create-k8s-rbac-tiller:
  cmd.run:
    - name: kubectl create -f rbac-tiller.yaml
    - cwd: /srv/k8s

init-k8s-helm-tiller:
  cmd.run:
    - name: helm init --service-account tiller
    - cwd: /srv/k8s

display-k8s-pods-services:
  cmd.run:
    - name: kubectl get pod,deploy,svc --all-namespaces

display-k8s-nodes:
  cmd.run:
    - name: kubectl get nodes

