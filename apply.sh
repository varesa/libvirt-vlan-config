
set -euo pipefail

network=$1

current() {
    virsh net-dumpxml $network
}

create() {
    echo "--Creating: $(get_name $1)"
    virsh net-update $network add portgroup $1
    echo
}

update() {
    echo "--Updating: $(get_name $1)"
    virsh net-update $network modify portgroup $1
    echo
}

remove() {
    echo "--Removing: $(get_name $1)"
    virsh net-update $network delete portgroup $1
    echo
}

get_name() {
   cat $1 | grep '<portgroup name' 
}

for portgroup_xml in create/*.xml; do
    if current | grep -q "$(get_name $portgroup_xml)"; then
        update $portgroup_xml
    else
        create $portgroup_xml
    fi
done

for portgroup_xml in remove/*.xml; do
    if current | grep -q "$(get_name $portgroup_xml)"; then
        remove $portgroup_xml
    else
        echo "--VLAN $portgroup_xml does not exist"
        echo
    fi
done
