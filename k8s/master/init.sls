{% from 'k8s/map.jinja' import k8s with context %}
{% import_yaml 'k8s/defaults.yaml' as k8s_defaults %}
{%- set k8sVersion = pillar['kubernetes']['version'] -%}
{%- set masterCount = pillar['kubernetes']['master']['count'] -%}

include:
  - k8s.master.etcd
  - k8s.master.firewall

/usr/bin/kube-apiserver:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kube-apiserver
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kube-controller-manager:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kube-controller-manager
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kube-scheduler:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kube-scheduler
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kubectl:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kubectl
    - skip_verify: true
    - group: root
    - mode: 755
{% if masterCount == 1 %}
/etc/systemd/system/kube-apiserver.service:
    file.managed:
    - source: salt://k8s/master/kube-apiserver.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644
{% elif masterCount == 3 %}
/etc/systemd/system/kube-apiserver.service:
    file.managed:
    - source: salt://k8s/master/kube-apiserver-ha.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644
{% endif %}

/etc/systemd/system/kube-controller-manager.service:
  file.managed:
    - source: salt://k8s/master/kube-controller-manager.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/etc/systemd/system/kube-scheduler.service:
  file.managed:
    - source: salt://k8s/master/kube-scheduler.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/var/lib/kubernetes/encryption-config.yaml:    
    file.managed:
    - source: salt://k8s/master/encryption-config.yaml
    - user: root
    - template: jinja
    - group: root
    - mode: 644

{%- set cniProvider = pillar['kubernetes']['worker']['networking']['provider'] -%}
{%- set cpu_mapped_names = [] -%}
{%- for server, cpuarch in salt['mine.get']('role:k8s-.*', 'cpuarch_list', 'grain_pcre') | dictsort() -%}
  {%- do cpu_mapped_names.append(k8s_defaults.k8s.cpuarches[cpuarch]) -%}
{%- endfor -%}
{% if cniProvider == "calico" %}
{% for mapped_arch in cpu_mapped_names|unique %}
/opt/calico/calico-{{ mapped_arch }}.yaml:
    file.managed:
    - source: salt://k8s/master/cni/calico/calico.tmpl.yaml
    - user: root
    - template: jinja
    - group: root
    - mode: 644
    - makedirs: true
    - context:
        cpu_arch_map: {{ mapped_arch }}
{% endfor %}
{% endif %}


kube-apiserver:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kube-apiserver.service
kube-controller-manager:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kube-controller-manager.service
kube-scheduler:
  service.running:
   - enable: True
   - watch:
     - /etc/systemd/system/kube-scheduler.service
