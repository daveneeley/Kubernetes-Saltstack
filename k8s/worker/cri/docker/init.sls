{%- set dockerVersion = pillar['kubernetes']['worker']['runtime']['docker']['version'] -%}
{%- set dockerdata = pillar['kubernetes']['worker']['runtime']['docker']['data-dir'] -%}

{{ dockerdata }}:
  file.directory:
    - user:  root
    - group:  root
    - mode:  '711'

{#
cri_run_docker_installer:
  cmd.run:
    - name: https://get.docker.com
#}

docker-latest-archive:
  archive.extracted:
    - name: /opt/
    - source: https://download.docker.com/linux/static/stable/{{ grains['osarch'] }}/docker-{{ dockerVersion }}.tgz
    - skip_verify: true
    - archive_format: tar
    - if_missing: /opt/docker/

/usr/bin/docker-containerd:
  file.symlink:
    - target: /opt/docker/docker-containerd

/usr/bin/docker-containerd-ctr:
  file.symlink:
    - target: /opt/docker/docker-containerd-ctr

/usr/bin/docker-containerd-shim:
  file.symlink:
    - target: /opt/docker/docker-containerd-shim

/usr/bin/dockerd:
  file.symlink:
    - target: /opt/docker/dockerd

/usr/bin/docker:
  file.symlink:
    - target: /opt/docker/docker

/usr/bin/docker-init:
  file.symlink:
    - target: /opt/docker/docker-init

/usr/bin/docker-proxy:
  file.symlink:
    - target: /opt/docker/docker-proxy

/usr/bin/docker-runc:
  file.symlink:
    - target: /opt/docker/docker-runc

/etc/systemd/system/docker.service:
    file.managed:
    - source: salt://k8s/worker/cri/docker/docker.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

docker:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/docker.service
