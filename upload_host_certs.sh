read -p "Certificate Authority Alias (e.g. MY_CA_DN):" CA_DN
echo ""
read -s -p "Destination Hosts SSH Username:" SSH_USERNAME

# Create a truststore for each node, using the IP addresses in the host_ips file
for NODE_IP_ADDR in `cat host_ips`
do
  # Transfer the truststore and keystore to the host
  scp ./$CA_DN/truststore.jks $SSH_USERNAME@$NODE_IP_ADDR:~/truststore.jks
  scp ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks $SSH_USERNAME@$NODE_IP_ADDR:~/keystore.jks

  # Move the files into their final destination and set permissions
  # Note this assumes the service username is "cassandra"
  ssh $SSH_USERNAME@$NODE_IP_ADDR "sudo mv /home/$SSH_USERNAME/truststore.jks /etc/dse/cassandra/truststore.jks --force; sudo chown cassandra:cassandra /etc/dse/cassandra/truststore.jks; sudo chmod 400 /etc/dse/cassandra/truststore.jks"

  ssh $SSH_USERNAME@$NODE_IP_ADDR "sudo mv /home/$SSH_USERNAME/keystore.jks /etc/dse/cassandra/keystore.jks --force; sudo chown cassandra:cassandra /etc/dse/cassandra/keystore.jks; sudo chmod 400 /etc/dse/cassandra/keystore.jks"

  echo "------------------------------------------------------------------------"
done
