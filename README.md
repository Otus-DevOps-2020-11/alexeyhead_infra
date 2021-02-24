### HW No. 11 (Lecture No. 13)

- The practical task of the methodical manual is performed
##### Local development with Vagrant
- Install vagrant
- In the `ansible` directory, created ` Vagrantfile` file with the definition of two VMs
- Performance check: created VMs and logged in via SSH
 ```
$ vagrant up
$ vagrant ssh appserver
```
- Vagrant provision for role "db"
- Check provision with command `vagrant provision dbserver`
- Created `ansible/playbooks/base.yml` for Python install and added into `site.yml`
```
---
- name: Check && install python
  hosts: all
  become: true
  gather_facts: False

  tasks:
    - name: Install python for Ansible
      raw: test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)
      changed_when: False
```
- Created `ansible/roles/db/tasks/install_mongo.yml` from `packer_db.yml` for install MongoDB
- Created `ansible/roles/db/tasks/config_mongo.yml` for configuration MongoDB
- In the role file `ansible/roles/db/tasks/main.yml` we will call tasks in the order we need
```
---
# tasks file for db
- name: Show info about the env this host belongs to
  debug:
    msg: "This host is in {{ env }} environment!!!"

- include: install_mongo.yml
- include: config_mongo.yml
```
- Check role and mongod port from apperver
```
$ vagrant provision dbserver
$ vagrant ssh appserver
vagrant@appserver:~$ telnet 10.10.10.10 27017
```
- Created `ansible/roles/app/tasks/ruby.yml` for Ruby install
- Created `ansible/roles/app/tasks/puma.yml` for puma configuration
- In the role file `ansible/roles/app/tasks/main.yml` we will call tasks in the order we need
```
---
# tasks file for app
- name: Show info about the env this host belongs to
  debug:
    msg: "This host is in {{ env }} environment!!!"

- include: ruby.yml
- include: puma.yml

```
- Checrk app role
```
$ vagrant provision appserver
```
##### Role parameterization
- Add var `deploy_user: appuser` in `ansible/roles/app/defaults/main.yml`
- Add var {{ deploy_user }} in `ansible/roles/app/templates/puma.service.j2`, `ansible/app/tasks/puma.yml` and `ansible/playbooks/deploy.yml`
##### Redefining variables
- Use `extra_vars` in `Vagrantfile` for redefining variables
```
 ansible.extra_vars = {
        "deploy_user" => "vagrant"
      }
```
- Added `Vagrantfile` configuration for correct application proxying with` nginx`
- Final output `Vagrantfile`
```
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => {"db_host" => "10.10.10.10"}
      }
      ansible.extra_vars = {
        deploy_user: "vagrant",
        nginx_sites: {
          default: [
            "listen 80",
            "server_name \"reddit\"",
            "location / { proxy_pass http://127.0.0.1:9292; }"
          ]
        }
      }
    end
  end
end
```
##### Role testing
- Install Molecule and Testinfra
- Venv preparation
- Added some test `ansible/roles/db/molecule/default/tests/test_default.py`
- Creating a test machine for Molecule from ``ansible/roles/db/molecule/default/molecule.yml``
- Testing the `db` role
```
$ pip install molecule-vagrant
$ molecule init scenario default -r db -d vagrant
$ molecule create
$ molecule list
$ molecule login -h instance
```
##### playbook.yml
- Added var `mongo_bind_ip` and `become: true` in  `ansible/roles/db/molecule/default/converge.yml` (actual for Molecule 3.*)
```
---
- name: Converge
  become: true
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: "Include db"
      include_role:
        name: "db"

```
- Checking
```
$ molecule converge
```
- Let's run the tests
```
$ molecule verify

INFO     Verifier completed successfully.
```
##### Task with *
-  Check if MongoDB port is reachable
- Add test in `ansible/roles/db/molecule/default/tests/test_default.py`

```
def test_mongodb_port_reachable(host):
    mongodb_port = host.addr('127.0.0.1')
    assert mongodb_port.port(27017).is_reachable

```
- Changed file `ansible/roles/db/molecule/default/molecule.yml` for using testinfra
```
---
dependency:
  name: galaxy
driver:
  name: vagrant
  provider:
    name: virtualbox
lint: |
  yamllint
platforms:
  - name: instance
    box: ubuntu/xenial64
provisioner:
  name: ansible
  lint: |
    ansible-lint
verifier:
  name: testinfra
  lint:
    name: flake8
```
- Let's run the tests
```
$ molecule verify

molecule/default/tests/test_default.py ...                               [100%]

============================== 3 passed in 2.73s ===============================
INFO     Verifier completed successfully.
```
##### Change provisioners in packer
- Used the roles `db` and` app` in playbooks `packer_db.yml` and` packer_app.yml`
- Used tags to run only the necessary tasks, tags are specified in the packer template, `ruby` for app.json and `install` for db.json

```
"provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_app.yml",
            "extra_arguments": ["--tags","{ruby,install}"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
        }
    ]
```

##### Connect role `db` via `requirements.yml` of both environments
- Made the role of `db` in a separate repository
- Removed the role `db` from the `infra` repository
- Add in `ansible/environments/{prod,stage}/requirements.yml`
