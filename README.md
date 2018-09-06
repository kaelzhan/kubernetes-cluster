# K8S
Deploy K8S Cluster with Vagrant

# 1. Component Version
kubenetes: 1.11.0 https://dl.k8s.io/v1.11.0/kubernetes-server-linux-amd64.tar.gz  
kubectl: 1.11.0	https://storage.googleapis.com/kubernetes-release/release/v1.11.0/kubernetes-client-linux-amd64.tar.gz  
etcd: 3.3.9	https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz  
flannel: 0.10.0 https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz  
docker: 17.03.0-ce https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz

# 2. Plugin
Coredns  
Dashboard  
Heapster (influxdb、grafana)  
Metrics-Server  
EFK (elasticsearch、fluentd、kibana)  

# 3. Policy  
## 3.1 kube-apiserver：
使用 keepalived 和 haproxy 实现 3 节点高可用；  
关闭非安全端口 8080 和匿名访问；  
在安全端口 6443 接收 https 请求；  
严格的认证和授权策略 (x509、token、RBAC)；  
开启 bootstrap token 认证，支持 kubelet TLS bootstrapping；  
使用 https 访问 kubelet、etcd，加密通信；  

## 3.2 kube-controller-manager：
3 节点高可用；  
关闭非安全端口，在安全端口 10252 接收 https 请求；  
使用 kubeconfig 访问 apiserver 的安全端口；  
自动 approve kubelet 证书签名请求 (CSR)，证书过期后自动轮转；  
各 controller 使用自己的 ServiceAccount 访问 apiserver；  

## 3.3 kube-scheduler：
3 节点高可用；  
使用 kubeconfig 访问 apiserver 的安全端口；

## 3.4 kubelet：
使用 kubeadm 动态创建 bootstrap token，而不是在 apiserver 中静态配置；  
使用 TLS bootstrap 机制自动生成 client 和 server 证书，过期后自动轮转；  
在 KubeletConfiguration 类型的 JSON 文件配置主要参数；  
关闭只读端口，在安全端口 10250 接收 https 请求，对请求进行认证和授权，拒绝匿名访问和非授权访问；  
使用 kubeconfig 访问 apiserver 的安全端口；  

## 3.5 kube-proxy：
使用 kubeconfig 访问 apiserver 的安全端口；  
在 KubeProxyConfiguration 类型的 JSON 文件配置主要参数；  
使用 ipvs 代理模式；  

## 3.6 plugins：
DNS：使用功能、性能更好的 coredns；  
Dashboard：支持登录认证；  
Metric：heapster、metrics-server，使用 https 访问 kubelet 安全端口；  
Log：Elasticsearch、Fluend、Kibana；  
Registry 镜像库：docker-registry、harbor；  



---
#
#
<meta http-equiv="refresh" content="0.5">



