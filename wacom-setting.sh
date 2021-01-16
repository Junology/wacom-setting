### wacom-setting.sh
###
### Copyright: Jun Yoshida, 2021
### License: CC0 (see LICENSE for details)

#!/bin/bash

# The following is based on the code snippet from
# https://stackoverflow.com/a/21189044/12889769
# while several changes were applied so that an arbitrary indent length is allowed in each level.
function parse_yaml {
    local prefix=$2 # Common prefix of the resulting variables.
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
    awk -F$fs -v top=0 '{
       indent_stk[0] = 0;
       indent = length($1);
       if (indent > indent_stk[top]) {top++; indent_stk[top] = indent;}
       else { while(indent < indent_stk[top]) {top--;} }
       vname_stk[top] = $2;
       if (length($3) > 0) {
          vn=""; for (i=0; i<top; i++) {vn=(vn)(vname_stk[i])("_")}
          printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
       }
    }'
}

function get_wacom_id {
    xsetwacom --list devices | grep "type: $1" | sed -e "s|^.*id:[[:space:]]*\([0-9]*\).*|\1|"
}

function apply_conf {
    # Recognize the target device type from the argument.
    local dev_type=$(echo $1 | awk -F'_' '{print $1}')
    # Find the device id of the given type
    local dev_id=$(get_wacom_id $dev_type)
    # Other parameters
    local params=$(echo $1 | sed -e "s|^[a-zA-Z]*_||" -e "y|_| |")
    # Make up and run the command
    for id in $dev_id; do
        local cmd="xsetwacom --set $id $params \"${!1}\""
        echo $cmd
        eval $cmd
    done
}

CONF_FILE=config.yml
CONF=$(parse_yaml $CONF_FILE)
CONF_VARS=$(parse_yaml $CONF_FILE | sed -e "s|^\([a-zA-Z0-9_]*\)=.*|\1|")

eval $CONF

for var in $CONF_VARS; do apply_conf $var; done

