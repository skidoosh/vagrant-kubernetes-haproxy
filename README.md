# Vagrant, Kubernetes and HAProxy stack

Simple local multi-node kubernetes environment. Ideal for learning and prototyping.

In the stack:
* Kubernetes controller
* Kubernetes workers
* HAProxy
* Vault (WIP)
* Consul (WIP)

## Setup

```
$ git clone git@github.com:skidoosh/vagrant-kubernetes-haproxy.git
$ sudo apt install kubectl vagrant virtualbox
$ vagrant plugin install vagrant-vbguest
$ echo "* 0.0.0.0/0 ::/0" | sudo tee /etc/vbox/networks.conf
$ cd vagrant-kubernetes-haproxy
$ vagrant up
```

Once the boxes are up and running:

```
$ export KUBECONFIG=$(pwd)/configs/config
```

## Installing the sample application
```
$ kubectl apply -f sample/wordpress/wordpress-mysql.yaml
$ kubectl apply -f sample/wordpress/wordpress-deploy.yaml
$ kubectl get po
```

## Rebuilding the loadbalancer
To rebuild the loadbalancer use the following commands:
```
$ chmod +x setup/loadbalancer.sh
$ ./tools/loadbalancer.sh
```

Once the script has finished. Open the configs/haproxy.cnf file to get the ports your service is running on then open your browser at http://localhost:[bind port from config].