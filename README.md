### HW No. 8 (Lecture No. 10)

- The practical task of the methodical manual is performed
- Create simple playbook `ansible/clone.yml`
- Run `ansible/clone.yml`
- The result of the playbook:

```bash
< PLAY RECAP >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

appserver                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
- Execute the command to remove dir with app `ansible app -m command -a 'rm -rf ~ / reddit'` and run the playbook again:

```bash
ansible app -m command -a 'rm -rf ~/reddit'
ansible-playbook clone.yml

PLAY RECAP ****************************************************************************************************************************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
The `changed` setting has changed because we deleted the application directory and cloned it again using the playbook.

##### Task with *

- Create `inventory.json` and `dynamic_inventory.sh` for dynamic inventory
- Run `ansible all -m ping -i dynamic_inventory.sh`:

```bash
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
- Added to the `ansible.cfg`  settings for working with `inventory.json`
