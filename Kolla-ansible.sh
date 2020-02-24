#!/bin/sh
pvcreate /dev/vda
vgcreate cinder-volumes /dev/vda
echo "nameserver 172.172.3.1" >> /etc/resolve.conf
echo "nameserver 8.8.8.8" >> /etc/resolve.conf
mkdir /etc/kolla/config
pip install "kolla-ansible==9.0.0"
cp -r /usr/local/share/kolla-ansible/etc_examples/kolla /etc/kolla/
cp /usr/local/share/kolla-ansible/ansible/inventory/* .
mkdir /etc/kolla/certificates/
git clone https://github.com/prashantsakharkar/certs.git /etc/kolla/certificates/
git clone https://github.com/prashantsakharkar/keyrings.git /etc/kolla/config/
sed -e '/kolla_internal_vip_address/ s/^#*/#/' -i /etc/kolla/globals.yml
sed -i 's/1048576//g' /usr/local/share/kolla-ansible/ansible/roles/neutron/tasks/precheck.yml
sed -i '/host_key_checking = False/s/^#//g' /etc/ansible/ansible.cfg
sed -i '/#pipelining = False/c pipelining = True' /etc/ansible/ansible.cfg

echo "kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
openstack_release: "train"
kolla_internal_vip_address: "10.10.10.63"
kolla_external_vip_address: "172.172.3.63"
kolla_external_fqdn: "kollaautotrainbionic.triliodata.demo"
kolla_enable_tls_external: "yes"
kolla_external_fqdn_cert: "/etc/kolla/certificates/tvm.cert.pem"
kolla_external_fqdn_cacert: "/etc/kolla/certificates/tvm.cert.pem"
network_interface: "eth2"
neutron_external_interface: "eth3"
keepalived_virtual_router_id: "99"
openstack_region_name: "USWEST"
enable_horizon: "yes"
enable_haproxy: "yes"
nova_compute_virt_type: "qemu"
enable_ceph: "no"
cinder_backend_ceph: "yes"
cinder_volume_group: "cinder-volumes"
enable_cinder_backend_lvm: "yes"
enable_cinder: "yes"" >> /etc/kolla/globals.yml

kolla-genpwd

secret=`cat /etc/kolla/passwords.yml | grep cinder_rbd | awk -F ' ' '{print $2}'`
sed  -i '/rbd_secret_uuid/c rbd_secret_uuid = '$secret /etc/kolla/config/cinder/cinder-volume.conf

echo "
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
#control01
#control02
#control03
172.172.3.62 ansible_ssh_user=root ansible_become=True ansible_ssh_pass=password
# The above can also be specified as follows:
#control[01:03]     ansible_user=kolla

# The network nodes are where your l3-agent and loadbalancers will run
# This can be the same as a host in the control group
[network]
#network01
#network02
172.172.3.62 ansible_ssh_user=root ansible_become=True ansible_ssh_pass=password
[compute]
#compute01
172.172.3.61 ansible_ssh_user=root ansible_become=True ansible_ssh_pass=password
[monitoring]
#monitoring01

# When compute nodes and control nodes use different interfaces,
# you need to comment out "api_interface" and other interfaces from the globals.yml
# and specify like below:
#compute01 neutron_external_interface=eth0 api_interface=em1 storage_interface=em1 tunnel_interface=em1

[storage]
#storage01
172.172.3.62 ansible_ssh_user=root ansible_become=True ansible_ssh_pass=password
[deployment]
localhost       ansible_connection=local

[baremetal:children]
control
network
compute
storage
monitoring

# You can explicitly specify which hosts run each project by updating the
# groups in the sections below. Common services are grouped together.
[chrony-server:children]
haproxy

[chrony:children]
control
network
compute
storage
monitoring

[collectd:children]
compute

[grafana:children]
monitoring

[etcd:children]
control

[influxdb:children]
monitoring

[prometheus:children]
monitoring

[kafka:children]
control

[karbor:children]
control

[kibana:children]
control

[telegraf:children]
compute
control
monitoring
network
storage

[elasticsearch:children]
control

[haproxy:children]
network

[hyperv]
#hyperv_host

[hyperv:vars]
#ansible_user=user
#ansible_password=password
#ansible_port=5986
#ansible_connection=winrm
#ansible_winrm_server_cert_validation=ignore

[mariadb:children]
control

[rabbitmq:children]
control

[outward-rabbitmq:children]
control

[qdrouterd:children]
control

[monasca-agent:children]
compute
control
monitoring
network
storage

[monasca:children]
monitoring

[storm:children]
monitoring

[mongodb:children]
control

[keystone:children]
control

[glance:children]
control

[nova:children]
control

[neutron:children]
network

[openvswitch:children]
network
compute
manila-share

[opendaylight:children]
network

[cinder:children]
control

[cloudkitty:children]
control

[freezer:children]
control

[memcached:children]
control

[horizon:children]
control

[swift:children]
control

[barbican:children]
control

[heat:children]
control

[murano:children]
control

[solum:children]
control

[ironic:children]
control

[ceph:children]
control

[magnum:children]
control

[qinling:children]
control

[sahara:children]
control

[mistral:children]
control

[manila:children]
control

[ceilometer:children]
control

[aodh:children]
control

[cyborg:children]
control
compute

[congress:children]
control

[panko:children]
control

[gnocchi:children]
control

[tacker:children]
control

[trove:children]
control

# Tempest
[tempest:children]
control

[senlin:children]
control

[vmtp:children]
control

[vitrage:children]
control

[watcher:children]
control

[rally:children]
control

[searchlight:children]
control

[octavia:children]
control

[designate:children]
control

[placement:children]
control

[bifrost:children]
deployment

[zookeeper:children]
control

[zun:children]
control

[skydive:children]
monitoring

[redis:children]
control

[blazar:children]
control

# Additional control implemented here. These groups allow you to control which
# services run on which hosts at a per-service level.
#
# Word of caution: Some services are required to run on the same host to
# function appropriately. For example, neutron-metadata-agent must run on the
# same host as the l3-agent and (depending on configuration) the dhcp-agent.

# Glance
[glance-api:children]
glance

# Nova
[nova-api:children]
nova

[nova-conductor:children]
nova

[nova-super-conductor:children]
nova

[nova-novncproxy:children]
nova

[nova-scheduler:children]
nova

[nova-spicehtml5proxy:children]
nova

[nova-compute-ironic:children]
nova

[nova-serialproxy:children]
nova

# Neutron
[neutron-server:children]
control

[neutron-dhcp-agent:children]
neutron

[neutron-l3-agent:children]
neutron

[neutron-metadata-agent:children]
neutron

[neutron-bgp-dragent:children]
neutron

[neutron-infoblox-ipam-agent:children]
neutron

[neutron-metering-agent:children]
neutron

[ironic-neutron-agent:children]
neutron

# Ceph
[ceph-mds:children]
ceph

[ceph-mgr:children]
ceph

[ceph-nfs:children]
ceph

[ceph-mon:children]
ceph

[ceph-rgw:children]
ceph

[ceph-osd:children]
storage

# Cinder
[cinder-api:children]
cinder

[cinder-backup:children]
storage

[cinder-scheduler:children]
cinder

[cinder-volume:children]
storage

# Cloudkitty
[cloudkitty-api:children]
cloudkitty

[cloudkitty-processor:children]
cloudkitty

# Freezer
[freezer-api:children]
freezer

[freezer-scheduler:children]
freezer

# iSCSI
[iscsid:children]
compute
storage
ironic

[tgtd:children]
storage

# Karbor
[karbor-api:children]
karbor

[karbor-protection:children]
karbor

[karbor-operationengine:children]
karbor

# Manila
[manila-api:children]
manila

[manila-scheduler:children]
manila

[manila-share:children]
network

[manila-data:children]
manila

# Swift
[swift-proxy-server:children]
swift

[swift-account-server:children]
storage

[swift-container-server:children]
storage

[swift-object-server:children]
storage

# Barbican
[barbican-api:children]
barbican

[barbican-keystone-listener:children]
barbican

[barbican-worker:children]
barbican

# Heat
[heat-api:children]
heat

[heat-api-cfn:children]
heat

[heat-engine:children]
heat

# Murano
[murano-api:children]
murano

[murano-engine:children]
murano

# Monasca
[monasca-agent-collector:children]
monasca-agent

[monasca-agent-forwarder:children]
monasca-agent

[monasca-agent-statsd:children]
monasca-agent

[monasca-api:children]
monasca

[monasca-grafana:children]
monasca

[monasca-log-api:children]
monasca

[monasca-log-transformer:children]
monasca

[monasca-log-persister:children]
monasca

[monasca-log-metrics:children]
monasca

[monasca-thresh:children]
monasca

[monasca-notification:children]
monasca

[monasca-persister:children]
monasca

# Storm
[storm-worker:children]
storm

[storm-nimbus:children]
storm

# Ironic
[ironic-api:children]
ironic

[ironic-conductor:children]
ironic

[ironic-inspector:children]
ironic

[ironic-pxe:children]
ironic

[ironic-ipxe:children]
ironic

# Magnum
[magnum-api:children]
magnum

[magnum-conductor:children]
magnum

# Qinling
[qinling-api:children]
qinling

[qinling-engine:children]
qinling

# Sahara
[sahara-api:children]
sahara

[sahara-engine:children]
sahara

# Solum
[solum-api:children]
solum

[solum-worker:children]
solum

[solum-deployer:children]
solum

[solum-conductor:children]
solum

[solum-application-deployment:children]
solum

[solum-image-builder:children]
solum

# Mistral
[mistral-api:children]
mistral

[mistral-executor:children]
mistral

[mistral-engine:children]
mistral

[mistral-event-engine:children]
mistral

# Ceilometer
[ceilometer-central:children]
ceilometer

[ceilometer-notification:children]
ceilometer

[ceilometer-compute:children]
compute

[ceilometer-ipmi:children]
compute

# Aodh
[aodh-api:children]
aodh

[aodh-evaluator:children]
aodh

[aodh-listener:children]
aodh

[aodh-notifier:children]
aodh

# Cyborg
[cyborg-api:children]
cyborg

[cyborg-agent:children]
compute

[cyborg-conductor:children]
cyborg

# Congress
[congress-api:children]
congress

[congress-datasource:children]
congress

[congress-policy-engine:children]
congress

# Panko
[panko-api:children]
panko

# Gnocchi
[gnocchi-api:children]
gnocchi

[gnocchi-statsd:children]
gnocchi

[gnocchi-metricd:children]
gnocchi

# Trove
[trove-api:children]
trove

[trove-conductor:children]
trove

[trove-taskmanager:children]
trove

# Multipathd
[multipathd:children]
compute
storage

# Watcher
[watcher-api:children]
watcher

[watcher-engine:children]
watcher

[watcher-applier:children]
watcher

# Senlin
[senlin-api:children]
senlin

[senlin-engine:children]
senlin

# Searchlight
[searchlight-api:children]
searchlight

[searchlight-listener:children]
searchlight

# Octavia
[octavia-api:children]
octavia

[octavia-health-manager:children]
octavia

[octavia-housekeeping:children]
octavia

[octavia-worker:children]
octavia

# Designate
[designate-api:children]
designate

[designate-central:children]
designate

[designate-producer:children]
designate

[designate-mdns:children]
network

[designate-worker:children]
designate

[designate-sink:children]
designate

[designate-backend-bind9:children]
designate

# Placement
[placement-api:children]
placement

# Zun
[zun-api:children]
zun

[zun-wsproxy:children]
zun

[zun-compute:children]
compute

# Skydive
[skydive-analyzer:children]
skydive

[skydive-agent:children]
compute
network

# Tacker
[tacker-server:children]
tacker

[tacker-conductor:children]
tacker

# Vitrage
[vitrage-api:children]
vitrage

[vitrage-notifier:children]
vitrage

[vitrage-graph:children]
vitrage

[vitrage-ml:children]
vitrage

# Blazar
[blazar-api:children]
blazar

[blazar-manager:children]
blazar

# Prometheus
[prometheus-node-exporter:children]
monitoring
control
compute
network
storage

[prometheus-mysqld-exporter:children]
mariadb

[prometheus-haproxy-exporter:children]
haproxy

[prometheus-memcached-exporter:children]
memcached

[prometheus-cadvisor:children]
monitoring
control
compute
network
storage

[prometheus-alertmanager:children]
monitoring

[prometheus-openstack-exporter:children]
monitoring

[prometheus-elasticsearch-exporter:children]
elasticsearch

[prometheus-blackbox-exporter:children]
monitoring

[masakari-api:children]
control

[masakari-engine:children]
control

[masakari-monitors:children]
compute
" > /home/vagrant/multinode

kolla-ansible -i /home/vagrant/multinode bootstrap-servers -vvv

kolla-ansible -i /home/vagrant/multinode prechecks -vvv

kolla-ansible -i /home/vagrant/multinode deploy -vvv

kolla-ansible post-deploy

pip install python-openstackclient python-glanceclient python-neutronclient