# Playbook-LNMP for CentOS 7.2
## HOW TO USE
### Install ansible
```
cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)

yum -y install ansible
vim /etc/ansible/hosts
...
[web_clusters]
X.X.X.X
...
ssh-copy-id -i ~/.ssh/id_rsa.pub root@X.X.X.X
```
### Install nginx1.12.2
```
ansible-playbook web.yml
```
### Install php7.0.2
```
ansible-playbook php.yml
```
### Install mysql5.6.23
```
ansible-playbook db.yml
```
