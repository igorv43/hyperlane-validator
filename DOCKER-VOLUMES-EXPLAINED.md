# 📦 Docker Volumes Explanation - Hyperlane with S3

This document explains the correct volume configuration when using AWS S3 for checkpoints.

## 🎯 Understanding the Difference

### ❌ Old Configuration (localStorage)

When we used `localStorage` for checkpoints:

```json
"checkpointSyncer": {
  "type": "localStorage",
  "path": "/etc/validator/terraclassic/checkpoint"
}
```

**Required volumes:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane          # Configuration files
  - ./validator:/etc/validator          # Local checkpoints + database
```

### ✅ New Configuration (S3)

With AWS S3 for checkpoints:

```json
"checkpointSyncer": {
  "type": "s3",
  "bucket": "hyperlane-validator-signatures-igorverasvalidador-terraclassic",
  "region": "us-east-1"
}
```

**Required volumes:**
```yaml
volumes:
  - ./hyperlane:/etc/hyperlane          # Configuration files
  - ./validator:/etc/data               # Only local database
```

## 📊 Detailed Comparison

| Component | Storage | Required Volume | Reason |
|-----------|---------|-----------------|--------|
| **Configurations** | Local | `./hyperlane:/etc/hyperlane` | ✅ JSON config files |
| **Database** | Local | `./validator:/etc/data` | ✅ Agent internal state |
| **Checkpoints** | S3 Bucket | ❌ None | Stored in AWS |

## 🔍 What Each Component Does

### 1. Configurations (`./hyperlane:/etc/hyperlane`)

**What it contains:**
- `agent-config.docker.json` - Chain configuration
- `validator.terraclassic.json` - Validator configuration
- `relayer.json` - Relayer configuration

**Why it needs a volume:**
- Files are read on initialization
- Allows updating configurations without rebuilding the image

**Example content:**
```bash
./hyperlane/
├── agent-config.docker.json
├── validator.terraclassic.json
└── relayer.json
```

### 2. Database (`./validator:/etc/data`)

**What it contains:**
- Validator internal state
- Last processed messages
- Sync indices
- Operational metadata

**Why it needs a volume:**
- Persistence between restarts
- Performance (doesn't need to resync)
- Operation history

**Path in code:**
```json
"db": "/etc/data/db"
```

**Example structure:**
```bash
./validator/
└── db/
    ├── CURRENT
    ├── LOCK
    ├── LOG
    ├── MANIFEST-000001
    └── *.sst files
```

### 3. Checkpoints (AWS S3)

**What it contains:**
- Signed checkpoints of messages
- Signed Merkle roots
- Validation metadata

**Why it does NOT need a volume:**
- ✅ Stored directly in S3
- ✅ Publicly accessible to other agents
- ✅ AWS redundancy and durability
- ✅ Doesn't take up local space

**Example in S3:**
```
s3://hyperlane-validator-signatures-igorverasvalidador-terraclassic/
├── checkpoint_0x1234...json
├── checkpoint_0x5678...json
└── checkpoint_0xabcd...json
```

## 🛠️ Correct Configuration

### docker-compose.yml

```yaml
services:
  relayer:
    container_name: hpl-relayer
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # Configurations
      - ./relayer:/etc/data           # Relayer database
    # Relayer reads checkpoints from S3 (allowLocalCheckpointSyncers: false)

  validator-terraclassic:
    container_name: hpl-validator-terraclassic
    image: gcr.io/abacus-labs-dev/hyperlane-agent:latest
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION:-us-east-1}
    volumes:
      - ./hyperlane:/etc/hyperlane    # Configurations
      - ./validator:/etc/data         # Validator database
    # Checkpoints go directly to S3, no volume needed!
```

### validator.terraclassic.json

```json
{
  "db": "/etc/data/db",              // Volume: ./validator
  "checkpointSyncer": {
    "type": "s3",                    // Goes to S3, no volume needed
    "bucket": "...",
    "region": "us-east-1"
  }
}
```

## 🔄 Migration from localStorage to S3

If you were already using localStorage and want to migrate to S3:

### Step 1: Backup Local Checkpoints (Optional)

```bash
# Backup old checkpoints
tar -czf validator-checkpoints-backup.tar.gz ./validator/terraclassic/checkpoint/
```

### Step 2: Update Configurations

```bash
# Edit validator.terraclassic.json
nano hyperlane/validator.terraclassic.json

# Change from:
"checkpointSyncer": {
  "type": "localStorage",
  "path": "/etc/validator/terraclassic/checkpoint"
}

# To:
"checkpointSyncer": {
  "type": "s3",
  "bucket": "your-s3-bucket",
  "region": "us-east-1"
}
```

### Step 3: Update docker-compose.yml

```bash
# Edit volumes
nano docker-compose.yml

# Change from:
volumes:
  - ./validator:/etc/validator

# To:
volumes:
  - ./validator:/etc/data
```

### Step 4: Restart Validator

```bash
# Stop container
docker-compose stop validator-terraclassic

# Remove old container
docker-compose rm -f validator-terraclassic

# Start with new configuration
docker-compose up -d validator-terraclassic

# Check logs
docker logs -f hpl-validator-terraclassic
```

### Step 5: Verify S3

```bash
# Check if checkpoints are being sent to S3
aws s3 ls s3://your-s3-bucket/ --region us-east-1

# Or via browser
# https://s3.console.aws.amazon.com/s3/buckets/your-s3-bucket
```

## 📈 Benefits of S3 vs localStorage

| Aspect | localStorage | S3 |
|--------|--------------|-----|
| **Availability** | Local only | Global (any agent) |
| **Durability** | Depends on disk | 99.999999999% (11 nines) |
| **Redundancy** | None | Automatic Multi-AZ |
| **Backup** | Manual | Automatic |
| **Disk space** | Consumes local | Doesn't consume |
| **Performance** | Fast (local) | Fast (AWS network) |
| **Cost** | Free | ~$0.023/GB/month |
| **Scalability** | Limited | Unlimited |

## 🔧 Troubleshooting

### Error: "Failed to write checkpoint to S3"

**Cause:** Incorrect AWS credentials or no permissions.

**Solution:**
```bash
# Check credentials
aws sts get-caller-identity

# Check bucket permissions
aws s3api get-bucket-policy --bucket your-bucket --region us-east-1
```

### Error: "Database already in use"

**Cause:** Volume mounted incorrectly or duplicate container.

**Solution:**
```bash
# Stop all containers
docker-compose down

# Check for orphaned containers
docker ps -a | grep validator

# Restart
docker-compose up -d validator-terraclassic
```

### Checkpoints don't appear in S3

**Cause:** Validator hasn't processed messages yet or incorrect bucket.

**Solution:**
```bash
# Check validator logs
docker logs hpl-validator-terraclassic | grep -i checkpoint

# Check bucket configuration
cat hyperlane/validator.terraclassic.json | grep -A 3 checkpointSyncer

# Test S3 access
aws s3 ls s3://your-bucket/ --region us-east-1
```

## 📁 Recommended Directory Structure

```
hyperlane-validator/
├── docker-compose.yml
├── .env                           # AWS Credentials
├── hyperlane/                     # Volume: /etc/hyperlane
│   ├── agent-config.docker.json
│   ├── validator.terraclassic.json
│   └── relayer.json
├── validator/                     # Volume: /etc/data
│   └── db/                        # Validator database
│       ├── CURRENT
│       └── *.sst
└── relayer/                       # Volume: /etc/data (relayer)
    └── db/                        # Relayer database
```

**Note:** There's no longer a `validator/terraclassic/checkpoint/` folder because checkpoints are in S3!

## 🔐 Security

### Checkpoints in S3

✅ **Public for reading** - Other agents need to read
❌ **Public for writing** - Only your validator should write

**Recommended Bucket Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789:user/your-iam-user"
      },
      "Action": ["s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::your-bucket/*"
    }
  ]
}
```

### Local Database

✅ **Private** - Only on server
🔒 **Backup recommended** - Copy periodically

**Backup Script:**
```bash
#!/bin/bash
# backup-validator-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
tar -czf validator-db-backup-${DATE}.tar.gz ./validator/db/
echo "Backup created: validator-db-backup-${DATE}.tar.gz"
```

## 📚 References

- [Hyperlane Validator Docs](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Docker Volumes Guide](https://docs.docker.com/storage/volumes/)

---

**✅ Summary:**

With S3, you only need **2 volumes**:
1. `./hyperlane:/etc/hyperlane` - Configurations ✅
2. `./validator:/etc/data` - Database ✅

Checkpoints go to S3, no local volume needed! 🚀

