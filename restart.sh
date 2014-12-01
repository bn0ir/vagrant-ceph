HOSTNAME='ceph'

hostname $HOSTNAME

restart ceph-mon id=ceph || start ceph-mon id=$HOSTNAME
restart ceph-osd id=0 || start ceph-osd id=0
restart ceph-osd id=1 || start ceph-osd id=1

/etc/init.d/radosgw restart

/etc/init.d/nginx restart

until $(curl --output /dev/null --silent --head --fail $HOSTNAME); do
    echo 'Waiting for radosgw'
    sleep 10
done

echo "Done"