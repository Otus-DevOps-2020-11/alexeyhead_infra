#!/bin/bash

yc_app=($(yc compute instance list | grep reddit-app | awk '{print $10}'))
yc_db=($(yc compute instance list | grep reddit-db |  awk '{print $10}'))

if [[ "$1" == "--list" ]]; then
#heredoc
cat<<EOF
{
    "_meta": {
        "hostvars": {
            "appserver": {
                "ansible_host": "${yc_app[0]}"
            },
            "dbserver": {
                "ansible_host": "${yc_db[0]}"
            }
        }
    },
    "all": {
        "hosts": [
            "app",
            "db",
            "ungrouped"
        ]
    },
    "app": {
        "hosts": [
            "appserver"
        ]
    },
    "db": {
        "hosts": [
            "dbserver"
        ]
    }
}
EOF

else
  echo "re-run with arguments"
fi
