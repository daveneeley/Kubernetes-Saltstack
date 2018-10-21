{% from 'k8s/map.jinja' import k8s with context %}

{% set CLUSTER_DOMAIN = salt['pillar.get']('kubernetes:domain') %}
{% set MASTER_HOSTNAME = salt['pillar.get']('kubernetes:master:hostname') %}
{% set CPU_ARCH_MAP = k8s.cpu_arch_map %}
{% set HELM_VERSION = salt['pillar.get']('kubernetes:global:helm-version') %}

setup-srv-k8s:
  file.directory:
    - name: /srv/k8s/manager-nodes
    - makedirs: True

download-k8s-manager-node-configs:
  file.recurse:
    - name: /srv/k8s/manager-nodes
    - source: salt://k8s/manager-nodes
    - template: jinja
    - include_pat: "*.yaml"
    - context:
        CLUSTER_DOMAIN: {{ CLUSTER_DOMAIN }}
        MASTER_HOSTNAME: {{ MASTER_HOSTNAME }}
        CPU_ARCH_MAP: {{ k8s.cpu_arch_map }}

create-k8s-rbac-calico:
  cmd.run:
    - name: kubectl create -f rbac-calico.yaml
    - cwd: /srv/k8s/manager-nodes

{% for yaml_file in salt['file.find']('/opt/calico/calico-*.yaml') %}
create-k8s-policy-controller-{{ yaml_file }}:
  cmd.run:
    - name: kubectl create -f {{ yaml_file }} && sleep 10
    - cwd: /srv/k8s/manager-nodes
{% endfor %}

{% for orderedFile in ('coredns', 'kubernetes-dashboard', 'heapster-rbac', 'influxdb', 'grafana', 'heapster') %}
create-k8s-{{ orderedFile }}:
  cmd.run:
    - name: kubectl create -f {{ orderedFile }}.yaml
    - cwd: /srv/k8s/manager-nodes
{% endfor %}

download-k8s-helm:
  archive.extracted:
    - name: /srv/k8s
    - source: https://kubernetes-helm.storage.googleapis.com/helm-{{ HELM_VERSION }}-linux-{{ k8s.cpu_arch_map }}.tar.gz
    - source_hash: https://kubernetes-helm.storage.googleapis.com/helm-{{ HELM_VERSION }}-linux-{{ k8s.cpu_arch_map }}.tar.gz.sha256

manage-k8s-helm:
  file.managed:
    - name: /usr/local/bin/helm
    - source: /srv/k8s/linux-{{ k8s.cpu_arch_map }}/helm
    - mode: 755
    - requires:
      - k8s.manager-nodes.download-k8s-helm

create-k8s-service-account-tiller:
  cmd.run:
    - name: kubectl create serviceaccount tiller --namespace kube-system
    - cwd: /srv/k8s/manager-nodes

create-k8s-rbac-tiller:
  cmd.run:
    - name: kubectl create -f rbac-tiller.yaml
    - cwd: /srv/k8s/manager-nodes

init-k8s-helm-tiller:
  cmd.run:
    - name: helm init --service-account tiller
    - cwd: /srv/k8s/manager-nodes

display-k8s-pods-services:
  cmd.run:
    - name: kubectl get pod,deploy,svc --all-namespaces

display-k8s-nodes:
  cmd.run:
    - name: kubectl get nodes

