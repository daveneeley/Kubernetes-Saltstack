{% from 'k8s/map.jinja' import k8s with context %}
download-cfssl:
  file.managed:
    - name: /usr/local/bin/cfssl
    - source: https://pkg.cfssl.org/R1.2/cfssl_linux-{{ k8s.cpu_arch_map }}
    - source_hash: https://pkg.cfssl.org/R1.2/SHA256SUMS
    - mode: 755

download-cfssljson:
  file.managed:
    - name: /usr/local/bin/cfssljson
    - source: https://pkg.cfssl.org/R1.2/cfssljson_linux-{{ k8s.cpu_arch_map }}
    - source_hash: https://pkg.cfssl.org/R1.2/SHA256SUMS
    - mode: 755

make-certs-temp-dir:
  file.directory:
    - name: /tmp/certs

download-source-certs:
  file.recurse:
    - name: /tmp/certs
    - source: salt://k8s/certs

manage-hostnames-in-kubernetes-csr:
  file.managed:
    - name: /tmp/certs/kubernetes-csr.json
    - source: salt://k8s/certs/kubernetes-csr.json
    - template: jinja

generate-ca-csr:
  cmd.run:
    - name: /usr/local/bin/cfssl gencert -initca ca-csr.json | /usr/local/bin/cfssljson -bare ca
    - cwd: /tmp/certs

generate-kubernetes-csr:
  cmd.run:
    - name: /usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | /usr/local/bin/cfssljson -bare kubernetes
    - cwd: /tmp/certs

{% for file in ['ca.pem', 'ca-key.pem', 'kubernetes-key.pem', 'kubernetes.pem'] %}
copy-generated-cert-{{ file }}:
  file.managed:
    - name: /srv/salt/k8s/certs/{{ file }}
    - source: /tmp/certs/{{ file }}
    - makedirs: True
{% endfor %}
