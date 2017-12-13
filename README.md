# Kubernetes-Saltstack
Saltstack recipe to deploy Kubernetes cluster from scratch. 

## I - Preparation

To prepare the deployment of the Kubernetes cluster, 

You need to prepare the Salt directory and create certificates on the `certs/` folder using `CFSSL tool`: 

```
git clone git@github.com:valentin2105/Kubernetes-Saltstack.git /srv/salt
ln -s /srv/salt/pillar /srv/pillar


curl -o cfssl https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
curl -o cfssljson https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
chmod +x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin/
```

### IMPORTANT Point
You need to modify `certs/kubernetes-csr.json` and put every Nodes (Masters/Workers) of your cluster in the `hosts` field.
You can use IP or Name (name is recommanded).
You can also modify the `certs/*json` files to match your cluster-name / country. (mandatory)

```
cd /srv/salt/certs 
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

```
After that, you need to tweak the `pillar/cluster_config.sls` to adapt version / configuration of Kubernetes : 

``
k8s:
  apiServerHost: k8s-master.domain.tld 
  kubernetesVersion: v1.8.5
  etcdVersion: v3.2.11
  calicoCniVersion: v1.11.1
  cniVersion: v0.6.0
  dockerVersion: 17.09.0-ce
  clusterDomain: cluster.local
  clusterIpRange: 10.32.0.0/16
  podsIpRange: 192.160.0.0/16
  kubeletToken: ch@nG3mee
  adminToken: ch@nG3mee
  calicoToken: ch@nG3mee
```

## II - Deployment

To deploy your Kubernetes cluster using this Salt-recipe, you first need to setup your Saltstack Master/Minion. 

The Kubernetes Master can also be the Salt Master if you want a small number of servers. 

#### The recommanded configuration is : 

- a Salt-Master
- a Kubernetes-Master (also Salt-minion)
- one or more Kubernetes-Workers (also Salt-minion)

The Minion's roles are matched with Salt Grains, so you need to apply theses grains on your servers : 

```
echo "role: k8s-master" >> /etc/salt/grains (on Kubernetes master)

echo "role: k8s-worker" >> /etc/salt/grains (on Kubernetes workers)
```


After that, you can apply your configuration on your minions :

```
# Install Master
salt -G 'roles:k8s-master' state.highstate

# Install Worker
salt -G 'roles:k8s-worker' state.highstate

```

## III - Good to know

- Kubernetes-master H/A will be available soon (need some tests).
- You can easily upgrade your cluster by changing values in `pillar/cluster_config.sls` and apply a `salt '*' state.highstate`.
