### HW No. 10 (Lecture No. 12)

- The practical task of the methodical manual is performed
- We went from playbooks to roles.

```bash
$ mkdir roles && cd roles
$ ansible-galaxy init app
- Role app was created successfully
$ ansible-galaxy init db
- Role db was created successfully
```
- Moved playbooks to separate roles
- Calling Roles

`ansible/app.yml`
```bash
---
- name: Configure App
  hosts: app
  become: true

  roles:
    - app
    - jdauphant.nginx

```
`ansible/db.yml`
```bash
---
- name: Configure MongoDB
  hosts: db
  become: true

  roles:
    - db

```
- Describing two environments
- Installing community-role `jdauphant.nginx`
- Configure reverse proxying for our application using nginx

`ansible/environments/stage/group_vars/app`

```bash
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:9292;
      }

```
##### Work with Ansible Vault

- Create file `vault.key` and DON'T FORGET add it to `.gitignore`. Better way - place this key out of repo.
```bash
date | md5sum | awk '{print $1}' > vault.key
```
- Add a playbook to create users  `ansible/playbooks/users.yml`
- Create a file with user data for each environment
- Encrypt files using `vault.key `
```bash
$ ansible-vault encrypt environments/prod/credentials.yml
$ ansible-vault encrypt environments/stage/credentials.yml
```
- Configure the use of dynamic inventory for stage and prod environments
- Add new vars `db_host` in dynamic_inventory.sh - we no longer need to manually add this variable to the inventory file
