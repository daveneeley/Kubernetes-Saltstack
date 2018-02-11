download-cfssl:
  file.managed:
    - name: /usr/local/bin/cfssl
    - source: https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    - mode: 755

download-cfssljson:
  file.managed:
    - name: /usr/local/bin/cfssljson
    - source: https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    - mode: 755

make-certs-temp-dir:
  file.directory:
    - name: /tmp/certs

download-source-certs:
  file.recurse:
    - name: /tmp/certs
    - source: salt://k8s-certs

generate-ca-csr:
  cmd.run:
    - name: /usr/local/bin/cfssl gencert -initca ca-csr.json | /usr/local/bin/cfssljson -bare ca
    - cwd: /tmp/certs

generate-kubernetes-csr:
  cmd.run:
    - name: /usr/local/bin/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | /usr/local/bin/cfssljson -bare kubernetes
