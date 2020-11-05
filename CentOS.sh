echo "開始安裝Graylog"
echo -n "請輸入Web管理IP(本機IP)     ==> " 
read WebIP
echo -n "請輸入Web管理密碼     ==> " 
read WebPassword

sudo yum -y install epel-release 
sudo yum -y install java-1.8.0-openjdk-headless.x86_64
sudo yum -y install pwgen

#vim /etc/yum.repos.d/mongodb-org.repo
cat << "EOF" > /etc/yum.repos.d/mongodb-org.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

sudo yum -y install mongodb-org

sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl start mongod.service
sudo systemctl --type=service --state=active | grep mongod

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

#vim /etc/yum.repos.d/elasticsearch.repo
cat << "EOF" > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/oss-6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo yum -y install elasticsearch-oss

sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
cluster.name: graylog
action.auto_create_index: false
EOT

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
sudo systemctl --type=service --state=active | grep elasticsearch

sudo rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-3.3-repository_latest.rpm
sudo yum -y update 
sudo yum -y install graylog-server graylog-integrations-plugins

#echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
#vim /etc/graylog/server/server.conf
#password_secret = 4a22d9475c162f25fe0127f79dc831c9fc168efe73f28f0527d769bd206e2780
#root_password_sha2 = 4a22d9475c162f25fe0127f79dc831c9fc168efe73f28f0527d769bd206e2780

echo "http_bind_address" = $WebIP:9000 >> /etc/graylog/server/server.conf
echo "root_timezone = Asia/Taipei" >> /etc/graylog/server/server.conf
PWDvar=$(echo -n $WebPassword | sha256sum | cut -d" " -f1)
sed -i "s/password_secret =/password_secret = $PWDvar/g" /etc/graylog/server/server.conf
sed -i "s/root_password_sha2 =/root_password_sha2 = $PWDvar/g" /etc/graylog/server/server.conf


sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl --type=service --state=active | grep graylog

sudo setsebool -P httpd_can_network_connect 1
sudo semanage port -a -t http_port_t -p tcp 9000
sudo semanage port -a -t http_port_t -p tcp 9200
sudo semanage port -a -t mongod_port_t -p tcp 27017


sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9200/udp
sudo firewall-cmd --permanent --add-port=27017/udp
sudo firewall-cmd --permanent --add-port=9990/udp
sudo firewall-cmd --permanent --add-port=1514/udp
sudo firewall-cmd --reload

echo "安裝完成"
echo "請重啟系統reboot"
echo "管理IP:http://$WebIP:9000"



