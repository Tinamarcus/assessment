#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wget gnupg curl

wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list

apt-get update
apt-get install -y mongodb-org=5.0.28

echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-database hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections
echo "mongodb-org-shell hold" | dpkg --set-selections
echo "mongodb-org-mongos hold" | dpkg --set-selections
echo "mongodb-org-tools hold" | dpkg --set-selections

cat > /etc/mongod.conf <<EOF
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
EOF

systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

sleep 10

MONGO_SHELL=""
if command -v mongosh >/dev/null 2>&1; then
  MONGO_SHELL="mongosh"
elif command -v mongo >/dev/null 2>&1; then
  MONGO_SHELL="mongo"
else
  echo "ERROR: No Mongo shell (mongosh/mongo) found; cannot initialize users." >&2
  exit 1
fi

# Wait for mongod to accept connections
for i in $(seq 1 30); do
  if ${MONGO_SHELL} --quiet --eval "db.runCommand({ ping: 1 }).ok" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Create admin user
${MONGO_SHELL} --quiet --eval 'db.getSiblingDB("admin").createUser({user:"admin",pwd:"admin123",roles:[{role:"root",db:"admin"}]})' || true

# Create application user in go-mongodb
${MONGO_SHELL} -u admin -p admin123 --authenticationDatabase admin --quiet \
  --eval 'db.getSiblingDB("go-mongodb").createUser({user:"appuser",pwd:"apppass123",roles:[{role:"readWrite",db:"go-mongodb"}]})' || true

# Verify credentials work
${MONGO_SHELL} -u admin -p admin123 --authenticationDatabase admin --quiet --eval 'db.runCommand({connectionStatus:1}).ok' >/dev/null
${MONGO_SHELL} -u appuser -p apppass123 --authenticationDatabase go-mongodb --quiet --eval 'db.runCommand({connectionStatus:1}).ok' >/dev/null

apt-get install -y awscli

cat > /usr/local/bin/mongodb-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR=/tmp/mongodb-backup
source /etc/mongodb-backup.env
BUCKET_NAME=${S3_BUCKET_NAME}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mongodb-backup-${TIMESTAMP}.tar.gz"

mkdir -p ${BACKUP_DIR}

mongodump --host localhost:27017 \
  --username admin \
  --password admin123 \
  --authenticationDatabase admin \
  --out ${BACKUP_DIR}

tar -czf /tmp/${BACKUP_FILE} -C ${BACKUP_DIR} .

aws s3 cp /tmp/${BACKUP_FILE} s3://${BUCKET_NAME}/${BACKUP_FILE}

rm -rf ${BACKUP_DIR}
rm -f /tmp/${BACKUP_FILE}

aws s3 ls s3://${BUCKET_NAME}/ | while read -r line; do
  createDate=$(echo $line | awk {'print $1" "$2'})
  createDate=$(date -d "$createDate" +%s)
  olderThan=$(date -d "7 days ago" +%s)
  if [[ $createDate -lt $olderThan ]]; then
    fileName=$(echo $line | awk {'print $4'})
    if [[ $fileName != "" ]]; then
      aws s3 rm s3://${BUCKET_NAME}/$fileName
    fi
  fi
done

echo "Backup completed: ${BACKUP_FILE}"
BACKUP_SCRIPT

chmod +x /usr/local/bin/mongodb-backup.sh

(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mongodb-backup.sh >> /var/log/mongodb-backup.log 2>&1") | crontab -

echo "S3_BUCKET_NAME=__S3_BUCKET_NAME__" > /etc/mongodb-backup.env
chmod 600 /etc/mongodb-backup.env

export S3_BUCKET_NAME=__S3_BUCKET_NAME__

systemctl restart mongod

echo "MongoDB setup completed successfully"