read -s -p "Certificate Password: " PASSWORD
echo ""
read -p "Certificate Authority Alias (e.g. MY_CA_DN): " CA_DN

##############################
# Create a root CA Certificate
##############################

mkdir -p ./$CA_DN/certs

echo "------------------------------------------------------------------------"

cat << EOF > ./$CA_DN/rootca.conf
# rootca.conf
[ req ]
# alias; used in other commands to reference specific certificates
distinguished_name = $CA_DN
prompt             = no
output_password    = $PASSWORD
default_bits       = 2048

[ $CA_DN ]
C  = US
ST = TX
L = Houston
O  = My Testing Certificate Authority
# By convention, the cluster name
OU = TestCluster
# By convention, the CA name
CN = TestClusterCA
EOF

# Create root key/certificate pair
openssl req -config ./$CA_DN/rootca.conf \
-new -x509 -nodes \
-keyout ./$CA_DN/rootca.key \
-out ./$CA_DN/rootca.crt \
-days 3650

# Verify the cert
openssl x509 -in ./$CA_DN/rootca.crt -text -noout

# Create a truststore for all nodes
keytool -keystore ./$CA_DN/truststore.jks \
  -storetype JKS \
  -importcert -file "./$CA_DN/rootca.crt" \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  -alias $CA_DN \
  -noprompt \
  2>/dev/null

echo "------------------------------------------------------------------------"


# clean up the conf file we created above
rm ./$CA_DN/rootca.conf

