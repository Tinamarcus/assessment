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

# Create required DB users if they don't exist yet
cat > /tmp/wiz-init-users.js <<'EOF'
function ensureUser(dbName, user, pwd, roles) {
  const d = db.getSiblingDB(dbName);
  const existing = d.getUser(user);
  if (!existing) {
    print("Creating user: " + dbName + "." + user);
    d.createUser({ user, pwd, roles });
  } else {
    print("User already exists: " + dbName + "." + user);
  }
}

ensureUser("admin", "admin", "admin123", [{ role: "root", db: "admin" }]);
ensureUser("go-mongodb", "appuser", "apppass123", [{ role: "readWrite", db: "go-mongodb" }]);
EOF

MONGO_SHELL=""
if command -v mongosh >/dev/null 2>&1; then
  MONGO_SHELL="mongosh"
elif command -v mongo >/dev/null 2>&1; then
  MONGO_SHELL="mongo"
else
  echo "ERROR: No Mongo shell (mongosh/mongo) found; cannot initialize users." >&2
  exit 1
fi

${MONGO_SHELL} --quiet /tmp/wiz-init-users.js

${MONGO_SHELL} --quiet --eval "db.getSiblingDB('admin').getUser('admin') ? 0 : (print('MISSING admin user'), 1)"
${MONGO_SHELL} --quiet --eval "db.getSiblingDB('go-mongodb').getUser('appuser') ? 0 : (print('MISSING appuser in go-mongodb'), 1)"

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