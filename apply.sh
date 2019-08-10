
set -euo pipefail

network=${1:-}

([ -n "$network" ] && virsh net-list --name | head -n-1 | grep -q $network) || (echo "First argument must be name of libvirt network"; exit 1)

path=${2:-}

([ -n "$path" ] && [ -d $path/create ]) || (echo "Second argument must be a path that contains directories create/ and remove/"; exit 1)
([ -n "$path" ] && [ -d $path/remove ]) || (echo "Second argument must be a path that contains directories create/ and remove/"; exit 1)

current() {
    virsh net-dumpxml $network
}

create() {
    echo "--Creating: $(get_name $1)"
    virsh net-update $network add portgroup $1 --live --config
    echo
}

update() {
    echo "--Updating: $(get_name $1)"
    virsh net-update $network modify portgroup $1 --live --config
    echo
}

remove() {
    echo "--Removing: $(get_name $1)"
    virsh net-update $network delete portgroup $1 --live --config
    echo
}

get_name() {
   cat $1 | grep '<portgroup name' 
}

for portgroup_xml in $path/create/*.xml; do
    if current | grep -q "$(get_name $portgroup_xml)"; then
        update $portgroup_xml
    else
        create $portgroup_xml
    fi
done

if [ ! "$(ls $path/remove | wc -l)" == 0 ]; then

    for portgroup_xml in $path/remove/*.xml; do
        if current | grep -q "$(get_name $portgroup_xml)"; then
            remove $portgroup_xml
        else
            echo "--VLAN $portgroup_xml does not exist"
            echo
        fi
    done
else
    echo "No VLANs to remove"
fi
