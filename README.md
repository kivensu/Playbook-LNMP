# Playbook-LNMP
## HOW TO USE
### Install ansible
```
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
### install php7.0.2
```
ansible-playbook php.yml
```
### install mysql5.6.23
```
ansible-playbook db.yml
```
