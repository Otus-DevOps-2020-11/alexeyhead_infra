#!/bin/bash

yc_app=($(yc compute instance list | grep reddit-app | awk '{print $4, $10}'))
yc_db=($(yc compute instance list | grep reddit-db |  awk '{print $4, $10}'))

if [[ "$1" == "--list" ]]; then
#heredoc
cat<<EOF
{
    "_meta": {
        "hostvars": {
            "${yc_app[0]}": {
                "ansible_host": "${yc_app[1]}"
            },
            "${yc_db[0]}": {
                "ansible_host": "${yc_db[1]}"
            }
        }
    },
    "all": {
        "children": [
            "app",
            "db",
            "ungrouped"
        ]
    },
    "app": {
        "hosts": [
            "${yc_app[0]}"
        ],
        "vars": {
            "db_host": "${yc_db[1]}"
            }
    },
    "db": {
        "hosts": [
            "${yc_db[0]}"
        ]
    }
}
EOF

else
  echo "re-run with arguments"
fi
