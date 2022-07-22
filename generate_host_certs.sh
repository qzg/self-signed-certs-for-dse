read -s -p "Certificate Password: " PASSWORD
echo ""
read -p "Certificate Authority Alias (e.g. MY_CA_DN): " CA_DN

# Create a truststore for each node, using the IP addresses in the host_ips file
for NODE_IP_ADDR in `cat host_ips`
do
  sh make_certs_for_ip.sh $CA_DN $NODE_IP_ADDR $PASSWORD
done
