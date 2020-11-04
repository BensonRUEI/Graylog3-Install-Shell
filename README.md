# Graylog3-Install-Shell



# 設備加入方法

###Forti Syslog
config global
config log syslogd2 setting
    set status enable
    set server "192.168.0.1"
    set port 1514
    set facility syslog
	end


#Cisco Netflow
!
flow record Flow-IN
 description IPv4 NetFlow
 match ipv4 source address
 match ipv4 destination address
 match transport source-port
 match transport destination-port
 match ipv4 protocol
 match interface input
 match ipv4 tos
 match flow direction
 collect interface output
 collect counter bytes long
 collect counter packets long
 collect transport tcp flags
 collect timestamp absolute first
 collect timestamp absolute last
!
flow record Flow-Out
 description IPv4 NetFlow
 match ipv4 source address
 match ipv4 destination address
 match transport source-port
 match transport destination-port
 match ipv4 protocol
 match interface output
 match ipv4 tos
 match flow direction
 collect interface input
 collect counter bytes long
 collect counter packets long
 collect transport tcp flags
 collect timestamp absolute first
 collect timestamp absolute last
!
!
flow exporter Flowview
 destination 192.168.0.1
 transport udp 9990
 template data timeout 60
!
!
flow monitor FLOW-MONITOR-Flow-IN
 exporter Flowview
 cache timeout active 60
 record Flow-IN
!
flow monitor FLOW-MONITOR-Flow-Out
 exporter Flowview
 cache timeout active 60
 record Flow-Out
!

int g1/0/1
 ip flow monitor FLOW-MONITOR-Flow-IN input
 ip flow monitor FLOW-MONITOR-Flow-Out output
