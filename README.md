# K8S
Use kubeadm to deploy K8S Cluster with Vagrant

# 1. Component Version
kubelet: 1.10.4   
kubectl: 1.10.4  
kubeadm: 1.10.4    
flannel: 0.10.0   
docker: 18.03.0-ce 

# 2. Plugin
Coredns  
Dashboard  
Heapster (influxdb、grafana)  

# 3. Meet  
## 3.1. Node节点不能加入master。(connect refused)
原因：节点有多个网卡，kubeadm init默认使用首个网卡，造成节点之间不能通讯。  
解决：kubeadm init时需使用--apiserver-advertise-address=172.27.129.11指定k8s使用的网卡接口IP。  
——：sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.27.129.11 --kubernetes-version=v1.10.4 --feature-gates=CoreDNS=true

## 3.2. Flannel 部署完成后，节点pod网段不能互通。
原因：同上，节点有多个网卡，flannel 部署时默认使用首个网卡，造成节点之间不能通讯。  
解决：在kube-flannel.yml 文件【DaemonSet】配置中 spec: template: spec: containers: args: 字段加入“- --iface=enp0s8” 配置，指定node 上flannel 使用的网络接口。  

## 3.3. 在pod 上不能 ping 通 service 接口。
原因：k8s services 只开放tcp与udp协议，不接受ping。  
解决：无  

## 3.4. 在kube-dns | core-dns pod 上使用nslookup命令不能解析k8s服务地址。
原因：k8s 限制 dns pod 之外的 pod 使用dns 服务。  
解决：无  

## 3.5. K8S service 开放 nodeport 后，外部不能访问。
原因：node 上 iptables 服务阻止了数据包经过 node 路由。  
解决：在所有节点上执行以下命令。  
——：sudo iptables -P FORWARD ACCEPT  

## 3.6. K8S 上mount volume时，pod 报错 "no such file or direcroty" 或者 “permission denied”
原因：注意pod可能会被部署到cluster 中任意node 节点上，可能pod 实际运行的node 节点文件不存在或权限不正确。  
解决：检查所有节点上对应文件是否存在，及设置的权限。  

## 3.7. Heapster 部署完成后，日志显示“x509: certificate signed by unknown authority"  
原因：Heapster默认连接 kubernetes api-server的安全端口，由于安全端口使用的证书为自签名证书，不能正常认证。  
解决：修改 kube-heapster.yml 文件【Deployment】配置中spec: template: spec: containers: command 字段的“--source”参数为以下内容。  
——：- --source=kubernetes:https://kubernetes.default:6443?inClusterConfig=false&insecure=true&auth=/tmp-k8s/config  
备注：The following options are available:  
- inClusterConfig - Use kube config in service accounts associated with Heapster's namespace. (default: true)  
- kubeletPort - kubelet port to use (default: 10255)  
- kubeletHttps - whether to use https to connect to kubelets (default: false)  
- insecure - whether to trust Kubernetes certificates (default: false)  
- auth - client auth file to use. Set auth if the service accounts are not usable.  
- useServiceAccount - whether to use the service account token if one is mounted at /var/run/secrets/kubernetes.io/serviceaccount/token (default: false)  

## 3.8. Heapster 添加“insecure=true”部署完成后，日志显示“403 Forbidden", response: "Forbidden (user=system:anonymous, verb=get, namespace=, resource=nodes/stats)"
原因：k8s 的api-server 需要用户通过认证才能访问数据，默认的system:anonymous用户没有权限访问需要的数据。  
解决：使用kubeconfig配置文件授权来访问 api-server, 命令同上，在“--source”参数中增加auth=/path/to/kubeconfigfile。  

## 3.9. Heapster 添加“kubeletHttps=true&kubeletPort=10250”部署完成后，日志显示"x509: cannot validate certificate for *.*.*.* because it doesn't contain any IP SANs"
原因：kubelet v1.10.4 默认开放安全的10250 API端口和非安全的 10255 只读端口，添加“kubeletHttps=true&kubeletPort=10250”参数将导致Heapster对kubelet的证书验证失败，原因同3.7。  
解决：去掉“kubeletHttps=true&kubeletPort=10250” option, heapster 访问kubelet 的10255 只读端口。  
  
# 4. Usage
- 1.安装VirtualBox与Vagrant。  
- 2.进入vagrant文件夹。  
- 3.执行" script /dev/dull vagrant up|tee vagrantUp.log "。  
- 4.执行" cat vagrantUp.log|grep 'kubeadm join'|awk -F'kube-node1:' '{print $2}' ", 保存产生的输出。  
- 5.分别执行" vagrant ssh kube-node2 " 和 " vagrant ssh kube-node3 "，通过SSH登录到kube-node2,kube-node3。  
- 6.分别在kube-node2和kube-node3上执行第4步产生的输出语句(前面添加"sudo ")。  


---
#
#
<meta http-equiv="refresh" content="0.5">



