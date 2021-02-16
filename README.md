### HW No. 8 (Lecture No. 10)

- The practical task of the methodical manual is performed
- Tried different approaches to writing playbooks
- Created app.yml for configuring App

```
- name: Configure App
  hosts: all
  become: true
  vars:
   db_host: 130.193.48.175
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes daemon-reload=yes

  handlers:
  - name: reload puma
    systemd: name=puma state=reloaded
```
- Created db.yml for configuring MongoDB

```
---
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted
```
- Created deploy.yml for deployment App

```
- name: Deploy App
  hosts: app
  tasks:
    - name: Install git
      become: true
      apt:
        name: git
        state: present
        update_cache: yes

    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      notify: restart puma

    - name: bundle install
      bundler:
        state: present
        chdir: /home/ubuntu/reddit

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted

```
- Created packer_app.yml for install Ruby and Bundler
```
---
- name: Install Ruby and Bundler
  hosts: all
  tasks:

    - name: sleep 40s
      pause:
        seconds: 40

    - name: Install packeges
      become: true
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - ruby-full
        - ruby-bundler
        - build-essential
        - git

```
- Created `packer_db.yml `for install MongoDB
```
---
- name: Install MongoDB
  hosts: all
  become: true
  tasks:

    - name: sleep 40s
      pause:
        seconds: 40

    - name: Install some necessary packages
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - apt-transport-https
        - ca-certificates

    - name: Add key for MongoDB
      apt_key:
        url: https://www.mongodb.org/static/pgp/server-4.2.asc
        state: present

    - name: Add MongoDB repo
      apt_repository:
        repo: deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse
        state: present

    - name: install MongoDB
      apt:
        name: mongodb-org
        state: present
        update_cache: yes

    - name: Configure mongod.service
      systemd:
        name: mongod
        enabled: yes

```
- Changed provisioner section for packer template app.json

```
"provisioners": [
        {
            "type": "ansible",
            "use_proxy": "false",
            "playbook_file": "ansible/packer_app.yml"
        }
    ]
```
- Changed provisioner section for packer template db.json
```
    "provisioners": [
        {
            "type": "ansible",
            "use_proxy": "false",
            "playbook_file": "ansible/packer_db.yml"
        }
    ]
```
- Created new images for VM
- Deploy new stage infra (don`t forget change vars for images id)
- Created `site.yml` for deploying App
```
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml

```
