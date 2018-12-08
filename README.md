<img src="https://i.imgur.com/SJAtDZk.png" width="460" height="125" >

Kubernetes-Saltstack provide an easy way to deploy H/A **Kubernetes Cluster** using Salt.

## Features

- Cloud-provider **agnostic**
- Support **high-available** clusters
- Use the power of **`Saltstack`**
- Made for **`systemd`** based Linux systems
- **Routed** networking by default (**`Calico`**)
- **CoreDNS** as internal DNS provider
- Latest Kubernetes release (**1.11.2**)
- Support **IPv6**
- Integrated **add-ons**
- **Composable** (CNI, CRI)
- **RBAC** & **TLS** by default
- Support Multi-Architecture
- Supports SaltStack Formulas pattern

# Quickstart
## Cloning and Targeting

- Install the formula according to your favorite formula distribution pattern, including Salt Package Manager.
- Symlink or copy pillar.example to /srv/pillar/k8s.sls. (See Pillar section below)
- Replace all tokens and keys in /srv/pillar/k8s.sls with new ones using a utility such as `pwgen 64`. Make other updates as desired.
- Update /srv/pillar/top.sls to target all masters and workers with new k8s pillar.
- Copy targets from top.sls to /srv/salt/top.sls. Update as follows:
  - replace `my-salt-master` with the hostname of your salt master, 
  - replace `my-k8s-masters` with a glob matching your k8s master nodes, and 
  - replace `my-k8s-workers` with a glob matching your k8s worker nodes.

## Adding Masters and Workers

- Run state.highstate on the k8s masters and workers.
- Run mine.update on the k8s masters and workers.
- Run state.highstate (or state.sls k8s.certs.setup) on the salt master
- Run state.highstate on the k8s masters and workers a second time.

```bash
# add grains
salt my-k8s\* state.highstate

# tell each new node to update the mine
salt -G role:k8s-\* mine.update

# generate certs on the salt master based on the mine data
# each hostname in the cluster must be in the cert
salt my-salt-master state.sls k8s.certs.setup

# install kubernetes on master and workers
salt -G role:k8s-\* state.highstate

#TODO: etcd doesn't restart as part of the highstate on the k8s-master nodes when certificates change. It should.
#TODO: kubelet doesn't restart on the worker nodes when the certificates change. It should.

```

Repeat the above steps in order when adding or removing capacity.

## k8s.certs.setup

Creates a CA and certificates in the `/srv/salt/k8s/certs` directory on the salt master using **`CfSSL`** tools. Only certs from this directory are synced to kubernetes workers and masters. Modify the `certs/*json` files in the formula to match your cluster-name / country (optional), then run `k8s.certs.setup` again on the salt master.

### IMPORTANT Point

As we generate our own CA and certificates for the cluster, **every hostname in the Kubernetes cluster** (masters & workers) MUST be included in the `certs/kubernetes-csr.json` (`hosts` field). This file is managed for you automatically by setting the `k8s-master` and `k8s-worker` grains and syncing the `fqdn` of those minions to the salt mine. The `fqdn` grain is used in the `hosts` field. You can use either public or private names, but they must be registered somewhere (DNS provider, internal DNS server, `/etc/hosts` file).

# Pillar Configuration
Edit `/srv/pillar/k8s.sls` to configure your future Kubernetes cluster :

```yaml
mine_functions:
  fqdn_list:
    - mine_function: grains.get
    - fqdn
  cpuarch_list:
    - mine_function: grains.get
    - cpuarch

kubernetes:
  version: v1.11.2
  domain: cluster.local
  master:
#    count: 1
#    hostname: master.domain.tld
#    ipaddr: 10.240.0.10
    count: 3
    cluster:
      node01:
        hostname: master01.domain.tld
        ipaddr: 10.240.0.10
      node02:
        hostname: master02.domain.tld
        ipaddr: 10.240.0.20
      node03:
        hostname: master03.domain.tld
        ipaddr: 10.240.0.30
    encryption-key: 'w3RNESCMG+o3GCHTUcrCHANGEMEq6CFV72q/Zik9LAO8uEc='
    etcd:
      version: v3.3.9
  worker:
    runtime:
      provider: docker
      docker:
        version: 18.03.0-ce
        data-dir: /dockerFS
    networking:
      cni-version: v0.7.1
      provider: calico
      calico:
        version: v3.2.3
        cni-version: v3.2.3
        calicoctl-version: v3.2.3
        controller-version: 3.2-release
        as-number: 64512
        token: hu0daeHais3aCHANGEMEhu0daeHais3a
        ipv4:
          range: 192.168.0.0/16
          nat: true
          ip-in-ip: true
        ipv6:
          enable: false
          nat: true
          interface: ens18
          range: fd80:24e2:f998:72d6::/64
  global:
    clusterIP-range: 10.32.0.0/16
    helm-version: v2.10.0
    dashboard-version: v1.10.0
    admin-token: Haim8kay1rarCHANGEMEHaim8kay1rar
    kubelet-token: ahT1eipae1wiCHANGEMEahT1eipae1wi
```
##### Don't forget to change hostnames & tokens  using command like `pwgen 64` !

If you want to enable IPv6 on pod's side, you need to change `kubernetes.worker.networking.calico.ipv6.enable` to `true`.

# Deployment

To deploy your Kubernetes cluster using this formula, you first need to setup your Saltstack master/Minion.  
You can use [Salt-Bootstrap](https://docs.saltstack.com/en/stage/topics/tutorials/salt_bootstrap.html) or [Salt-Cloud](https://docs.saltstack.com/en/latest/topics/cloud/) to enhance the process. 

By default the Salt-master is the Kubernetes master. You can have them as different nodes if needed but the `k8s.manager-nodes` state requires `kubectl` and access to the `pillar` files.

#### The recommended configuration is:

The Minion's roles are matched with `Salt Grains` (kind of inventory), so you need to define the `role: k8s-master` and `role: k8s-worker` grains on your servers.

- one or three Kubernetes-master (Salt-master & minion) get `role: k8s-master`

- one or more Kubernetes-workers (Salt-minion) get `role: k8s-worker`

If you want a small cluster, a master can be a worker too. 

With the grains set, the salt mine synced, and the certs updated, you can apply your configuration (`highstate`) :

```bash
# Apply Kubernetes master configurations
salt -G 'role:k8s-master' state.highstate 

~# kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}

# Apply Kubernetes worker configurations
salt -G 'role:k8s-worker' state.highstate

~# kubectl get nodes
NAME                STATUS    ROLES     AGE       VERSION   EXTERNAL-IP   OS-IMAGE 
k8s-salt-worker01   Ready     <none>     5m       v1.11.2    <none>        Ubuntu 18.04.1 LTS 
k8s-salt-worker02   Ready     <none>     5m       v1.11.2    <none>        Ubuntu 18.04.1 LTS 
k8s-salt-worker03   Ready     <none>     5m       v1.11.2    <none>        Ubuntu 18.04.1 LTS 
k8s-salt-worker04   Ready     <none>     5m       v1.11.2    <none>        Ubuntu 18.04.1 LTS 
```

To enable add-ons on the Kubernetes cluster, you can launch the `k8s.manager-nodes` state :

```bash
~# salt my-salt-master state.sls k8s.manager-nodes

~# kubectl get pod --all-namespaces
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-fcc5cb8ff-tfm7v 1/1       Running   0          1m
kube-system   calico-node-bntsh                       1/1       Running   0          1m
kube-system   calico-node-fbicr                       1/1       Running   0          1m
kube-system   calico-node-badop                       1/1       Running   0          1m
kube-system   calico-node-rcrze                       1/1       Running   0          1m
kube-system   coredns-d44664bbd-596tr                 1/1       Running   0          1m
kube-system   coredns-d44664bbd-h8h6m                 1/1       Running   0          1m
kube-system   kubernetes-dashboard-7c5d596d8c-4zmt4   1/1       Running   0          1m
kube-system   tiller-deploy-546cf9696c-hjdbm          1/1       Running   0          1m
kube-system   heapster-55c5d9c56b-7drzs               1/1       Running   0          1m
kube-system   monitoring-grafana-5bccc9f786-f4lf2     1/1       Running   0          1m
kube-system   monitoring-influxdb-85cb4985d4-rd776    1/1       Running   0          1m
```

- Tested on Debian, Ubuntu and Fedora.
- You can easily upgrade software version on your cluster by changing values in `/srv/pillar/k8s.sls` and apply a `state.highstate`.
- This configuration use ECDSA certificates (you can switch to `rsa` if needed in `certs/*.json`).
- You can tweak Pod's IPv4 pool, enable IPv6, change IPv6 pool, enable IPv6 NAT (for no-public networks), change BGP AS number, Enable IPinIP (to allow routes sharing of different cloud providers).
- If you use `salt-ssh` or `salt-cloud` you can quickly scale new workers.
