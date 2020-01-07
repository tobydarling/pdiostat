#!/bin/bash

# Get iostat output from all machines in a cluster, show the
# top 10 stressed disks.

field=15
usage() {
    echo "$0 [-g group] [-k sort_field] [-s search_string]"
    echo "  group: pdsh group defined in .dsh/group/"
    echo "  sort_field: integer 3-15, sorting iostat output, default=$field"
    echo "  search_string: string to highlight, eg \"ceph1:.*\""
    echo 
    echo "Eg: monitor the ceph cluster, sorting on await, highlighting ceph1:sda activity:"
    echo "  $0 -g ceph -k 11 -s \"ceph1:.*sda .*\""
    exit
}

while getopts 'g:k:s:h' opt; do
    case $opt in
        g) group=$OPTARG ;;
        k) field=$OPTARG ;;
        s) s=$(echo "$OPTARG" | sed 's; ;[[:space:]];g') || s="thisllnevermatch" ;;
        h) usage ;;
    esac
done
shift $((OPTIND - 1))
[ -z "$group" ] && usage

pdsh -g $group hostname > /dev/null || { echo "Do you have a file ~/.dsh/group/$group?"; exit; }
export group field

f() {
    pdsh -g $group 'iostat -mxy 1 1 | egrep -v "^dm|^md" ' | tr -s ' ' | sort -rnk$field -t' ' | head -30 | (echo -ne 'host\t'; iostat -mx | grep Device; cat -) | column -tx | sed -e "s/\($1\)/`tput smso`\1`tput rmso`/g"
}
### old beegfs2 only has 12 columns of iostat output :-(
f2() {
    pdsh -g beegfs2 'iostat -mxy 1 1' | tr -s ' ' | sort -rnk13 -t' ' | head -10 | (echo -ne 'host\t'; (ssh rat13 iostat -mx | grep Device); cat -) | column -tx | sed -e "s/\($1\)/`tput smso`\1`tput rmso`/g"
}

export -f f f2
case $group in
    beegfs2)
        watch --color -n5 bash -c '"'f2 $s'"'
    ;;
    * )
        watch --color -n5 bash -c '"'f $s'"'
    ;;
esac


# watch -n5 "pdsh -g beegfs3 'iostat -mxy 1 1 | grep -v Device' | tr -s ' ' | sort -rnk15 -t' ' | head -10 | (echo -ne 'host\t'; iostat -mx | grep Device; cat -) | column -tx"
