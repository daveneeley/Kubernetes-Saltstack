{% from 'k8s/map.jinja' import k8s with context %}
{%- set k8sVersion = pillar['kubernetes']['version'] -%}
{%- set os = salt['grains.get']('os') -%}
{%- set enableIPv6 = pillar['kubernetes']['worker']['networking']['calico']['ipv6']['enable'] -%}
{%- set criProvider = pillar['kubernetes']['worker']['runtime']['provider'] -%}

include:
  - k8s.worker.cri.{{ criProvider }}
  - k8s.worker.cni
{% if os == "Debian" or os == "Ubuntu" %}
glusterfs-client:
  pkg.latest

conntrack:
  pkg.latest

nfs-common:
  pkg.latest
{% endif %} 

{% if os == "Raspbian" %}
k8s_raspbian_remove_swap:
  cmd.run:
    - name: dphys-swapfile swapoff && dphys-swapfile uninstall && update-rc.d dphys-swapfile remove

{% set cmdline = salt['cmd.run']('cat /boot/cmdline.txt') %}
{% for cmd in ("cgroup_enable=cpuset","cgroup_memory=1","cgroup_enable=memory") %}
{% if not cmd in cmdline %}
k8s_raspbian_append_{{ cmd }}_to_boot_cmdline:
  cmd.run:
    - name: sed -i 's/$/ {{ cmd }}/' /boot/cmdline.txt
{% endif %}
{% endfor %}
{# TODO: a reboot is required if anything in this block is executed #}
{% endif %}

socat:
  pkg.latest

vm.max_map_count:
  sysctl.present:
    - value: 2097152

/usr/bin/kubelet:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kubelet
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kube-proxy:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/{{ k8s.cpu_arch_map }}/kube-proxy
    - skip_verify: true
    - group: root
    - mode: 755

/var/lib/kubelet:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 700

/var/lib/kubelet/kubeconfig:
    file.managed:
    - source: salt://k8s/worker/kubeconfig
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/etc/systemd/system/kubelet.service:
    file.managed:
    - source: salt://k8s/worker/kubelet.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/etc/systemd/system/kube-proxy.service:
  file.managed:
    - source: salt://k8s/worker/kube-proxy.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

kubelet:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kubelet.service
      - /var/lib/kubernetes/kubernetes.pem

kube-proxy:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kube-proxy.service

{% if enableIPv6 == true %}
net.ipv6.conf.all.forwarding:
  sysctl.present:
    - value: 1
{% endif %}
