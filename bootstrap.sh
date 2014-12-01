HOSTUUID=`uuidgen`
HOSTNAME='ceph'
HOSTIP='192.168.200.2'
HOSTNET='192.168.200.0/24'

hostname $HOSTNAME

wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
echo deb http://ceph.com/debian-giant/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list
apt-get update && apt-get install -y ceph ceph-deploy ntpdate radosgw nginx curl

mkdir -p /home/ceph && cd /home/ceph

printf '192.168.200.2 ceph\n' >> /etc/hosts

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
ssh-keygen -y -f /root/.ssh/id_rsa > /root/.ssh/id_rsa.pub
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
ssh-keyscan -H $HOSTNAME >> /root/.ssh/known_hosts

cd /home/ceph/ && \
mkdir /var/lib/ceph/mon/ceph-$HOSTNAME && \
mkdir /tmp/$HOSTNAME

printf "[global]\nfsid = $HOSTUUID\n" > /etc/ceph/ceph.conf && \
printf "mon initial members = $HOSTNAME\n" >> /etc/ceph/ceph.conf && \
printf "mon host = $HOSTIP\n" >> /etc/ceph/ceph.conf

ceph-authtool --create-keyring /tmp/$HOSTNAME/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
ceph-authtool /tmp/$HOSTNAME/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
monmaptool --create --add $HOSTNAME $HOSTIP --fsid $HOSTUUID /tmp/$HOSTNAME/monmap
ceph-mon --mkfs -i $HOSTNAME --monmap /tmp/$HOSTNAME/monmap --keyring /tmp/$HOSTNAME/ceph.mon.keyring
printf "auth cluster required = cephx\nauth service required = cephx\nauth client required = cephx\nosd pool default size = 2\nosd pool default min size = 2\nosd pool default pg num = 333\nosd pool default pgp num = 333\nosd crush chooseleaf type = 0\n" >> /etc/ceph/ceph.conf && \
touch /var/lib/ceph/mon/ceph-$HOSTNAME/done && \

start ceph-mon id=$HOSTNAME
touch /var/lib/ceph/mon/ceph-$HOSTNAME/upstart

mkdir -p /var/lib/ceph/osd/ceph-0
ceph osd create
ceph-osd -i 0 --mkkey --mkfs --mkjournal --osd-journal /var/lib/ceph/osd/ceph-0/journal
ceph auth add osd.0 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-0/keyring
ceph osd crush add-bucket $HOSTNAME host
ceph osd crush move $HOSTNAME root=default
ceph osd crush add osd.0 1.0 host=$HOSTNAME

mkdir -p /var/lib/ceph/osd/ceph-1
ceph osd create
ceph-osd -i 1 --mkkey --mkfs --mkjournal --osd-journal /var/lib/ceph/osd/ceph-1/journal
ceph auth add osd.1 osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-1/keyring
ceph osd crush add osd.1 1.0 host=$HOSTNAME

start ceph-osd id=0
start ceph-osd id=1

cd /etc/ceph
ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.keyring
ceph-authtool /etc/ceph/ceph.client.radosgw.keyring -n client.radosgw.ceph --gen-key
ceph-authtool -n client.radosgw.ceph --cap osd 'allow rwx' --cap mon 'allow rwx' /etc/ceph/ceph.client.radosgw.keyring
ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.ceph -i /etc/ceph/ceph.client.radosgw.keyring

printf '[client.radosgw.ceph]\n' >> /etc/ceph/ceph.conf && \
printf 'host = ceph\n' >> /etc/ceph/ceph.conf && \
printf 'user = root\n' >> /etc/ceph/ceph.conf && \
printf 'rgw dns name = radosgw.local\n' >> /etc/ceph/ceph.conf && \
printf 'keyring = /etc/ceph/ceph.client.radosgw.keyring\n' >> /etc/ceph/ceph.conf && \
printf 'rgw socket path = /var/run/ceph/ceph.radosgw.ceph.fastcgi.sock\n' >> /etc/ceph/ceph.conf && \
printf 'log file = /var/log/radosgw/client.radosgw.ceph.log\n' >> /etc/ceph/ceph.conf

rsync /vagrant/configs/nginx.conf /etc/nginx/sites-available/default

radosgw-admin user create --uid=runner --display-name="Application runner" --email=`cat /vagrant/configs/email` > /vagrant/s3.key
