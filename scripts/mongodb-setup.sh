#!/bin/bash
# MongoDB Setup Script for Wiz Exercise
# Installs outdated MongoDB version (>1 year old) and configures it

set -e

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wget gnupg curl

# Install MongoDB 5.0 (released in 2021, >1 year outdated as of 2024)
# This is intentionally an older version as per exercise requirements
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list

apt-get update
apt-get install -y mongodb-org=5.0.28

# Prevent MongoDB from being upgraded
echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-database hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections
echo "mongodb-org-shell hold" | dpkg --set-selections
echo "mongodb-org-mongos hold" | dpkg --set-selections
echo "mongodb-org-tools hold" | dpkg --set-selections

# Configure MongoDB
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

# Start MongoDB
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
sleep 10

# Create admin user and application user
mongosh --eval "
db = db.getSiblingDB('admin');
db.createUser({
  user: 'admin',
  pwd: 'admin123',
  roles: [{ role: 'root', db: 'admin' }]
});

db = db.getSiblingDB('go-mongodb');
db.createUser({
  user: 'appuser',
  pwd: 'apppass123',
  roles: [{ role: 'readWrite', db: 'go-mongodb' }]
});
"

# Install AWS CLI for backups
apt-get install -y awscli

# Create backup script
cat > /usr/local/bin/mongodb-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
# MongoDB Backup Script - Runs daily via cron

BACKUP_DIR=/tmp/mongodb-backup
source /etc/mongodb-backup.env
BUCKET_NAME=${S3_BUCKET_NAME}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mongodb-backup-${TIMESTAMP}.tar.gz"

mkdir -p ${BACKUP_DIR}

# Create backup
mongodump --host localhost:27017 \
  --username admin \
  --password admin123 \
  --authenticationDatabase admin \
  --out ${BACKUP_DIR}

# Compress backup
tar -czf /tmp/${BACKUP_FILE} -C ${BACKUP_DIR} .

# Upload to S3
aws s3 cp /tmp/${BACKUP_FILE} s3://${BUCKET_NAME}/${BACKUP_FILE}

# Cleanup
rm -rf ${BACKUP_DIR}
rm -f /tmp/${BACKUP_FILE}

# Keep only last 7 days of backups in S3
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

# Set up daily cron job for backups
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/mongodb-backup.sh >> /var/log/mongodb-backup.log 2>&1") | crontab -

# Create environment file for backup script
echo "S3_BUCKET_NAME=__S3_BUCKET_NAME__" > /etc/mongodb-backup.env
chmod 600 /etc/mongodb-backup.env

# Export for immediate use
export S3_BUCKET_NAME=__S3_BUCKET_NAME__

# Restart MongoDB to apply security settings
systemctl restart mongod

echo "MongoDB setup completed successfully"

