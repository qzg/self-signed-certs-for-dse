CA_DN=$1
NODE_IP_ADDR=$2
PASSWORD=$3

HOSTNAME_SUFFIX=".internal"
KEY_OU="TestCluster"
KEY_ORG="Test Company"

NODE_HOSTNAME=`echo $NODE_IP_ADDR | tr "." "-"`
NODE_HOSTNAME="ip-$NODE_HOSTNAME$HOSTNAME_SUFFIX"

printf "\nCreating files for $NODE_HOSTNAME\n"

touch ./$CA_DN/san_config.conf
echo "subjectAltName=DNS:$NODE_HOSTNAME,IP:$NODE_IP_ADDR" >> ./$CA_DN/san_config.conf

# Generate a keystore with a key pair
keytool -genkeypair -keyalg RSA \
  -alias $NODE_HOSTNAME \
  -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -storepass $PASSWORD \
  -keypass $PASSWORD \
  -validity 3650 \
  -keysize 2048 \
  -dname "CN=$NODE_HOSTNAME, OU=$KEY_OU, O=$KEY_ORG, C=US" \
  -ext "san=ip:$NODE_IP_ADDR" \
  2>/dev/null

# Optional sanity check
#keytool -list \
  #-keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  #-storepass $PASSWORD \
  #2>/dev/null

# Generate a signing request (CSR) from the keystore
keytool -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -alias $NODE_HOSTNAME \
  -certreq -file ./$CA_DN/certs/$NODE_IP_ADDR-signing_request.csr \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  2>/dev/null

# Sign the CSR
openssl x509 -req -CA "./$CA_DN/rootca.crt" \
  -CAkey "./$CA_DN/rootca.key" \
  -in ./$CA_DN/certs/$NODE_IP_ADDR-signing_request.csr \
  -out ./$CA_DN/certs/$NODE_IP_ADDR-signing_request.crt_signed \
  -days 3650 \
  -CAcreateserial \
  -passin pass:$PASSWORD \
  -extfile ./$CA_DN/san_config.conf

# Optional sanity check
#openssl verify -CAfile "./$CA_DN/rootca.crt" ./$CA_DN/certs/$NODE_IP_ADDR-signing_request.crt_signed

# Import the root certificate into the node keystore
keytool -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -alias $CA_DN \
  -importcert -file "./$CA_DN/rootca.crt" \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  -noprompt \
  2>/dev/null

# Optional sanity check
keytool -list \
  -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -storepass $PASSWORD \
  2>/dev/null

# Import the node's CA-signed cert into the node keystore
keytool -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -alias $NODE_HOSTNAME \
  -importcert -file ./$CA_DN/certs/$NODE_IP_ADDR-signing_request.crt_signed \
  -keypass $PASSWORD \
  -storepass $PASSWORD \
  -noprompt \
  2>/dev/null

# export the node's public key in PEM format
keytool -exportcert -rfc -noprompt \
  -alias $NODE_HOSTNAME \
  -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -storepass $PASSWORD \
  -file ./$CA_DN/certs/$NODE_IP_ADDR-public.pem \
  2>/dev/null

# export the node's private key 
keytool -importkeystore -noprompt -deststoretype PKCS12 \
  -srckeystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -srcstorepass $PASSWORD \
  -deststorepass $PASSWORD \
  -destkeystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.p12 \
  2>/dev/null

# convert the node's private key to PEM format
openssl pkcs12 -nomacver -nocerts \
  -in ./$CA_DN/certs/$NODE_IP_ADDR-keystore.p12 \
  -password pass:$PASSWORD \
  -passout pass:$PASSWORD \
  -out ./$CA_DN/certs/$NODE_IP_ADDR-private.pem


# Optional sanity check
keytool -list \
  -keystore ./$CA_DN/certs/$NODE_IP_ADDR-keystore.jks \
  -storepass $PASSWORD \
  2>/dev/null

rm ./$CA_DN/san_config.conf
