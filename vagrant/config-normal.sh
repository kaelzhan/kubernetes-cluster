#!/bin/bash
###################
#      root       #
###################
sudo su root
sudo chmod -R 777 /vagrant/*
sudo cp -r /vagrant/cert/.ssh /root/
sudo mv /etc/hosts /etc/hosts.bak
sudo cp -r /vagrant/config/hosts  /etc/hosts
###配置更新源,安装必要软件
sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
sudo cp /vagrant/config/sources.list /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk-headless apt-transport-https ca-certificates curl software-properties-common rpcbind nfs-common
# 获取公钥，显示ok即表示正确
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# 添加docker及k8s相关源
sudo cp /vagrant/config/kubernetes.list /etc/apt/sources.list.d/kubernetes.list
apt-get update
# 调整系统 TimeZone
sudo timedatectl set-timezone Asia/Shanghai
# 将当前的 UTC 时间写入硬件时钟
sudo timedatectl set-local-rtc 0
# 重启依赖于系统时间的服务
sudo systemctl restart rsyslog
#sudo passwd 会要求填入密码，下面将$pass作为密码传入
pass=123456
echo root:$pass | sudo chpasswd root
sudo useradd k8s
echo k8s:$pass | sudo chpasswd k8s
sudo echo "%k8s	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers
###配置无密码登录
sudo cp /root/.ssh/private/kube-node$1.pri /root/.ssh/id_rsa
sudo chmod 400 /root/.ssh/id_rsa
eval `ssh-agent`
ssh-add /root/.ssh/id_rsa
sudo mkdir -p /home/k8s/.ssh
sudo cp -r /root/.ssh/* /home/k8s/.ssh/
sudo chown -R k8s:k8s /home/k8s
###################
#       k8s       #
###################
sudo su k8s
eval `ssh-agent`
ssh-add /home/k8s/.ssh/id_rsa
sudo cp /etc/skel/.bashrc /home/k8s/
sudo cp /vagrant/config/.profile /home/k8s/
sudo chown k8s:k8s /home/k8s/.bashrc
sudo chown k8s:k8s /home/k8s/.profile
source /home/k8s/.profile
###配置环境变量及系统参数
sudo sh -c "echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >>/root/.bashrc"
sudo sh -c "echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>/root/.bashrc"
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >>~/.bashrc
echo 'PATH=/opt/k8s/bin:$PATH:$HOME/bin:$JAVA_HOME/bin' >>~/.bashrc
sudo iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
sudo iptables -P FORWARD ACCEPT
sudo echo '/sbin/iptables -P FORWARD ACCEPT' >>/etc/rc.local
sudo swapoff -a
sudo cp /vagrant/config/kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sudo sysctl -p /etc/sysctl.d/kubernetes.conf
sudo cat /proc/sys/net/ipv6/conf/all/disable_ipv6
###关闭selinux
#sudo setenforce 0
#sudo echo "SELINUX=disabled" >> /etc/selinux/config
###修改root密码，并添加用户k8s与docker
###安装docker
sudo mkdir -p /etc/docker/
sudo mkdir -p /data/docker
docker_version=$(apt-cache madison docker-ce | grep 18.03 | head -1 | awk '{print $3}')
kube_version=$(apt-cache madison kubelet | grep 1.10.4 | head -1 | awk '{print $3}')
sudo apt-get install -y docker-ce=$docker_version
sudo gpasswd -a k8s docker
sudo apt-get install -y kubelet=$kube_version kubeadm=$kube_version kubectl=$kube_version --allow-unauthenticated
sudo sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
# kubeadm
if [[ $1 = 1 ]] ; then
	sudo sysctl net.bridge.bridge-nf-call-iptables=1
	sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
	sudo kubeadm init --config /vagrant/config/kubeadm-config.yml
	sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
	sudo mkdir -p /root/.kube
	sudo cp -r /etc/kubernetes/admin.conf /root/.kube/config
	sudo chmod 777 /root/.kube/config
	sudo mkdir -p /home/k8s/.kube
	sudo cp -r /etc/kubernetes/admin.conf /home/k8s/.kube/config
	sudo chown -R k8s:k8s /home/k8s/.kube/*
	chmod 777 /home/k8s/.kube/config
	sudo cp -r /vagrant/kube-flannel.yml /home/k8s/
	sudo cp -r /vagrant/yml /home/k8s/
	sudo chown -R k8s:k8s /home/k8s/*
	sleep 10s
	cd /home/k8s/
	kubectl apply -f ./kube-flannel.yml
	kubectl create -f yml/
elif [[ $1 != 1 ]]; then
	sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
	sudo mkdir -p /home/k8s/.kube
	sudo scp kube-node1:/home/k8s/.kube/config /home/k8s/.kube/
	sudo chown -R k8s:k8s /home/k8s/.kube/*
	chmod 777 /home/k8s/.kube/config
	sudo mkdir -p /root/.kube
	sudo cp /home/k8s/.kube/config /root/.kube/
	sudo chmod 777 /root/.kube/config
fi
