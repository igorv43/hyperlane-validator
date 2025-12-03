# 🔑 Setup AWS: KMS + S3

## ⚠️ **IMPORTANT: AWS KMS Support by Protocol**

| Protocol | Chains | AWS KMS Support |
|----------|--------|-----------------|
| **EVM** | BSC, Ethereum, Polygon, etc. | ✅ Supported |
| **Sealevel** | Solana | ❌ NOT Supported |
| **Cosmos** | Terra Classic, Osmosis, etc. | ❌ NOT Supported |

**AWS KMS works ONLY for EVM chains (BSC, Ethereum, Polygon, etc.).**

**Solana and Cosmos chains must use hexKey (local private keys).**

**Terra Classic (Cosmos) must use hexKey (local private keys).**

---

## 📋 **What You Need to Configure**

| Resource | Usage | Chain |
|---------|-------|-------|
| **IAM User** | AWS Credentials | All |
| **S3 Bucket** | Store validator signatures | Terra Classic |
| **KMS Key (BSC)** | Sign relayer transactions | BSC (optional) |
| **KMS Key (Ethereum)** | Sign relayer transactions | Ethereum (optional) |
| **KMS Key (Solana)** | Sign relayer transactions | Solana (optional) |
| ~~KMS Key (Terra)~~ | ~~Doesn't work~~ | ❌ Don't use |

---

## 🚀 **Quick Configuration**

### For Terra Classic Validator:

- ✅ **S3 Bucket** (public signatures)
- ✅ **hexKey** (local private key)
- ❌ **DO NOT use KMS**

### For BSC Relayer (Optional):

- ✅ **KMS Key** (sign BSC transactions)
- ✅ **hexKey** for Terra Classic

### For Ethereum Relayer (Optional):

- ✅ **KMS Key** (sign Ethereum transactions)
- ✅ **hexKey** for Terra Classic

### For Solana Relayer (Optional):

- ❌ **KMS Key** (NOT supported for Solana)
- ✅ **hexKey** (local private key for Solana)
- ✅ **hexKey** for Terra Classic

---

## 📚 **Configuration Steps**

### STEP 1: Create IAM User

**Reference:** [Create an IAM user](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-an-iam-user)

#### 1.1 Access AWS IAM Console

1. Go to: https://us-east-1.console.aws.amazon.com/iamv2/home
2. In the left sidebar, click **"Users"**
3. Click the orange **"Add users"** button

#### 1.2 Configure User

1. **Username**:
   ```
   hyperlane-validator
   ```

2. Click **"Next"**
3. **DO NOT** select any permissions yet
4. Click **"Next"** again
5. Click **"Create user"**

#### 1.3 Create Access Keys

1. Click on the newly created user to open their details
2. Click on the **"Security credentials"** tab
3. Scroll down to **"Access keys"**
4. Click **"Create access key"**
5. Select **"Application running outside AWS"**
6. Click **"Next"**
7. (Optional) Add a description, example: "Hyperlane Validator Keys"
8. Click **"Create access key"**
9. **⚠️ IMPORTANT**: Copy and securely save: `Access key ID` and `Secret access key`.
10. Click **"Done"**

#### 1.4 Save to .env

```bash
cd /home/lunc/hyperlane-validator
cp .env.example .env
nano .env
```

**⚠️ IMPORTANT:** Replace the placeholder values with your **actual AWS credentials** from your IAM user.

**Content (example - replace with your values):**
```bash
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

**What to fill:**
- `AWS_ACCESS_KEY_ID`: Your IAM user's Access Key ID (starts with `AKIA...`)
- `AWS_SECRET_ACCESS_KEY`: Your IAM user's Secret Access Key (long random string)
- `AWS_REGION`: AWS region (usually `us-east-1`)

**⚠️ SECURITY WARNING:**
- Never commit `.env` file to Git (already in `.gitignore`)
- Never share your AWS credentials
- These are **sensitive credentials** - keep them secure!

**Protect file:**
```bash
chmod 600 .env
```

#### 1.5 Add IAM Permissions for KMS and S3

**⚠️ IMPORTANT:** Your IAM user needs permissions to create and use KMS keys, and to access S3.

1. Go to: https://us-east-1.console.aws.amazon.com/iamv2/home
2. Click **"Users"** in the left sidebar
3. Click on your user: `hyperlane-validator` (or `hyperlane-validator-terraclassic`)
4. Click **"Add permissions"** → **"Create inline policy"**
5. Click **"JSON"** tab
6. Paste this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetPublicKey",
        "kms:Sign",
        "kms:CreateAlias",
        "kms:ListAliases",
        "kms:ListKeys"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::hyperlane-validator-signatures-*",
        "arn:aws:s3:::hyperlane-validator-signatures-*/*"
      ]
    }
  ]
}
```

7. Click **"Next"**
8. **Policy name**: `HyperlaneValidatorPolicy`
9. Click **"Create policy"**

**What this policy allows:**
- **KMS permissions**: Create keys, describe keys, get public keys, sign transactions
- **S3 permissions**: Write, read, delete checkpoints in your validator bucket

---

### STEP 2: Create S3 Bucket

**Reference:** [AWS Signatures Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)

#### 2.1 Access S3 Console

1. Go to: https://s3.console.aws.amazon.com/s3/home?region=us-east-1
2. Click **"Create bucket"**

#### 2.2 Configure Bucket

1. **Bucket name**:
   ```
   hyperlane-validator-signatures-YOUR-NAME
   ```
   
   **Example:**
   ```
   hyperlane-validator-signatures-YOUR-NAME-terraclassic
   ```
   
   **⚠️ Replace `YOUR-NAME` with your unique identifier (e.g., your username or validator name)**

2. **AWS Region**: `US East (N. Virginia) us-east-1`

3. **Object Ownership**: `ACLs disabled (recommended)`

4. **Block Public Access settings**:
   - ⚠️ **UNCHECK** "Block all public access"
   - ✅ **CHECK** the checkbox "I acknowledge..."

5. **Bucket Versioning**: `Disable`

6. **Default encryption**: `Server-side encryption with Amazon S3 managed keys (SSE-S3)`

7. Click **"Create bucket"**

#### 2.3 Configure Bucket Policy

1. Click on the created bucket
2. Go to the **"Permissions"** tab
3. Scroll to **"Bucket policy"**
4. Click **"Edit"**

**Paste this policy** (replace the values):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/hyperlane-validator"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

**⚠️ Replace:**
- `YOUR-BUCKET-NAME` → Your bucket name
- `YOUR-ACCOUNT-ID` → Your AWS account ID (12 digits)

**Example (replace with your values):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::hyperlane-validator-signatures-YOUR-NAME-terraclassic",
        "arn:aws:s3:::hyperlane-validator-signatures-YOUR-NAME-terraclassic/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/hyperlane-validator"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::hyperlane-validator-signatures-YOUR-NAME-terraclassic/*"
    }
  ]
}
```

**⚠️ Replace:**
- `YOUR-NAME` → Your unique identifier (e.g., your username or validator name)
- `123456789012` → Your AWS account ID (12 digits)

5. Click **"Save changes"**

#### 2.4 Test Access

```bash
# Test listing
aws s3 ls s3://YOUR-BUCKET-NAME/

# Test writing
echo "test" > test.txt
aws s3 cp test.txt s3://YOUR-BUCKET-NAME/
rm test.txt

# Test public read (without credentials)
curl https://YOUR-BUCKET-NAME.s3.us-east-1.amazonaws.com/test.txt

# Clean up
aws s3 rm s3://YOUR-BUCKET-NAME/test.txt
```

---

### STEP 3: Create KMS Key for BSC (Optional)

**⚠️ ONLY if running relayer with BSC!**

**Reference:** [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#cast-cli)

#### 3.1 Access KMS Console

1. Go to: https://console.aws.amazon.com/kms
2. Make sure you're in region **US East (N. Virginia) us-east-1**
3. Click **"Create key"**

#### 3.2 Configure Key

**Step 1: Configure key**

1. **Key type**: `Asymmetric`
2. **Key usage**: `Sign and verify`
3. **Key spec**: `ECC_SECG_P256K1`
4. Click **"Next"**

**Step 2: Add labels**

1. **Alias**: `hyperlane-relayer-signer-bsc`
2. **Description** (optional): `Hyperlane Relayer signer key for BSC`
3. Click **"Next"**

**Step 3: Define key administrative permissions**

1. Select your user (optional)
2. Click **"Next"**

**Step 4: Define key usage permissions**

1. **This account**: Search and select ☑️ `hyperlane-validator`
2. Click **"Next"**

**Step 5: Review**

1. Review settings
2. Click **"Finish"**

#### 3.3 Create Key via CLI (Alternative Method)

**If you prefer using CLI instead of Console:**

```bash
# Create the KMS key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1
```

**Example response (with fictional data):**
```json
{
    "KeyMetadata": {
        "AWSAccountId": "123456789012",
        "KeyId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "Arn": "arn:aws:kms:us-east-1:123456789012:key/a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "CreationDate": "2025-12-03T13:08:15.991000-03:00",
        "Enabled": true,
        "Description": "",
        "KeyUsage": "SIGN_VERIFY",
        "KeyState": "Enabled",
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "ECC_SECG_P256K1",
        "KeySpec": "ECC_SECG_P256K1",
        "SigningAlgorithms": [
            "ECDSA_SHA_256"
        ],
        "MultiRegion": false
    }
}
```

**⚠️ IMPORTANT:** 
- Copy the `KeyId` from the response (it's a UUID like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
- **DO NOT** use your Access Key ID (`AKIA...`) - that's for authentication only!

**Then create the alias using the Key ID from the response:**
```bash
# Use the KeyId from the response above (example: a1b2c3d4-e5f6-7890-abcd-ef1234567890)
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-bsc \
  --target-key-id a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --region us-east-1
```

**Complete example workflow:**
```bash
# Step 1: Create key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1

# Response shows KeyId: a1b2c3d4-e5f6-7890-abcd-ef1234567890

# Step 2: Create alias using the KeyId from Step 1
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-bsc \
  --target-key-id a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --region us-east-1

# Success! No output means it worked.
```

**⚠️ Common Error:** 
- ❌ **WRONG**: Using Access Key ID (`AKIA...`) as `target-key-id`
  ```bash
  # ❌ This will fail!
  aws kms create-alias --target-key-id AKIAWK73T2L43T4Y46WJ
  ```
- ✅ **CORRECT**: Using Key ID (UUID format) from the `create-key` response
  ```bash
  # ✅ This works!
  aws kms create-alias --target-key-id a1b2c3d4-e5f6-7890-abcd-ef1234567890
  ```

#### 3.4 Note Information

After creation, note:

```
Alias: hyperlane-relayer-signer-bsc
Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  (UUID format, NOT Access Key ID!)
ARN: arn:aws:kms:us-east-1:ACCOUNT-ID:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Region: us-east-1
```

#### 3.5 Verify Address

```bash
# Get BSC address
cast wallet address --aws alias/hyperlane-relayer-signer-bsc

# Or use script
./get-kms-addresses.sh
```

---

### STEP 4: Create KMS Key for Ethereum (Optional)

**⚠️ ONLY if running relayer with Ethereum!**

Same process as BSC, but with different alias:

**Via CLI:**
```bash
# Step 1: Create the key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1
```

**Example response:**
```json
{
    "KeyMetadata": {
        "AWSAccountId": "123456789012",
        "KeyId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
        "Arn": "arn:aws:kms:us-east-1:123456789012:key/b2c3d4e5-f6a7-8901-bcde-f23456789012",
        "CreationDate": "2025-12-03T13:10:20.123000-03:00",
        "Enabled": true,
        "KeyUsage": "SIGN_VERIFY",
        "KeyState": "Enabled",
        "KeySpec": "ECC_SECG_P256K1",
        "SigningAlgorithms": ["ECDSA_SHA_256"]
    }
}
```

```bash
# Step 2: Create alias using KeyId from response above
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-ethereum \
  --target-key-id b2c3d4e5-f6a7-8901-bcde-f23456789012 \
  --region us-east-1
```

**Get address:**
```bash
cast wallet address --aws alias/hyperlane-relayer-signer-ethereum
```

---

### STEP 5: Create KMS Key for Solana (Optional)

**⚠️ ONLY if running relayer with Solana!**

Same process as BSC, but with different alias:

**Via CLI:**
```bash
# Step 1: Create the key
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1
```

**Example response:**
```json
{
    "KeyMetadata": {
        "AWSAccountId": "123456789012",
        "KeyId": "c3d4e5f6-a7b8-9012-cdef-345678901234",
        "Arn": "arn:aws:kms:us-east-1:123456789012:key/c3d4e5f6-a7b8-9012-cdef-345678901234",
        "CreationDate": "2025-12-03T13:12:30.456000-03:00",
        "Enabled": true,
        "KeyUsage": "SIGN_VERIFY",
        "KeyState": "Enabled",
        "KeySpec": "ECC_SECG_P256K1",
        "SigningAlgorithms": ["ECDSA_SHA_256"]
    }
}
```

```bash
# Step 2: Create alias using KeyId from response above
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-solana \
  --target-key-id c3d4e5f6-a7b8-9012-cdef-345678901234 \
  --region us-east-1
```

**Get address:**
```bash
# Address will be shown in relayer logs after startup
# Or get from KMS public key
aws kms get-public-key \
  --key-id alias/hyperlane-relayer-signer-solana \
  --region us-east-1
```

---

## ✅ **AWS Resources Checklist**

### Required (Validator):

- [ ] ✅ IAM user created: `hyperlane-validator`
- [ ] ✅ Access Key ID and Secret obtained and saved in `.env`
- [ ] ✅ S3 bucket created and configured
- [ ] ✅ Bucket policy configured (public read + IAM write)

### Optional (Relayer BSC):

- [ ] ⏳ KMS key for BSC: `hyperlane-relayer-signer-bsc`
- [ ] ⏳ BSC address obtained and funded

### Optional (Relayer Ethereum):

- [ ] ⏳ KMS key for Ethereum: `hyperlane-relayer-signer-ethereum`
- [ ] ⏳ Ethereum address obtained and funded

### Optional (Relayer Solana):

- [ ] ⏳ KMS key for Solana: `hyperlane-relayer-signer-solana`
- [ ] ⏳ Solana address obtained and funded

### ❌ DO NOT Create:

- [ ] ~~KMS key for Terra Classic~~ (Cosmos does not support KMS)

---

## 🔧 **Configure Validator (Terra Classic)**

### validator.terraclassic.json

```bash
cp hyperlane/validator.terraclassic.json.example hyperlane/validator.terraclassic.json
nano hyperlane/validator.terraclassic.json
```

**Configuration:**

```json
{
  "db": "/etc/data/db",
  "checkpointSyncer": {
    "type": "s3",
    "bucket": "YOUR-BUCKET-NAME",  // ← Replace
    "region": "us-east-1"
  },
  "originChainName": "terraclassic",
  "validator": {
    "type": "hexKey",  // ← hexKey, NOT aws
    "key": "0xYOUR_PRIVATE_KEY"  // ← Your private key
  },
  "chains": {
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY",  // ← Same key
        "prefix": "terra"
      }
    }
  }
}
```

**Protect file:**
```bash
chmod 600 hyperlane/validator.terraclassic.json
```

---

## 🔧 **Configure Relayer (Optional)**

### relayer.json

```bash
cp hyperlane/relayer.json.example hyperlane/relayer.json
nano hyperlane/relayer.json
```

**Configuration Example (Terra + BSC):**

```json
{
  "db": "/etc/data/db",
  "relayChains": "terraclassic,bsc",
  "allowLocalCheckpointSyncers": "false",
  "gasPaymentEnforcement": [{ "type": "none" }],
  
  "whitelist": [
    {"originDomain": [1325], "destinationDomain": [56]},
    {"originDomain": [56], "destinationDomain": [1325]}
  ],
  
  "chains": {
    "bsc": {
      "signer": {
        "type": "aws",  // ← AWS KMS for BSC (EVM)
        "id": "alias/hyperlane-relayer-signer-bsc",
        "region": "us-east-1"
      }
    },
    
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",  // ← hexKey for Terra (Cosmos)
        "key": "0xYOUR_PRIVATE_KEY",
        "prefix": "terra"
      }
    }
  }
}
```

**Configuration Example (Terra + Ethereum):**

```json
{
  "relayChains": "terraclassic,ethereum",
  "chains": {
    "ethereum": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-ethereum",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY",
        "prefix": "terra"
      }
    }
  }
}
```

**Configuration Example (Terra + Solana):**

```json
{
  "relayChains": "terraclassic,solanatestnet",
  "chains": {
    "solanatestnet": {
      "signer": {
        "type": "aws",
        "id": "alias/hyperlane-relayer-signer-solana",
        "region": "us-east-1"
      }
    },
    "terraclassic": {
      "signer": {
        "type": "cosmosKey",
        "key": "0xYOUR_PRIVATE_KEY",
        "prefix": "terra"
      }
    }
  }
}
```

**Protect file:**
```bash
chmod 600 hyperlane/relayer.json
```

---

## 🐳 **Run Docker**

### Start Validator

```bash
# Start validator
docker-compose up -d validator-terraclassic

# View logs
docker logs -f hpl-validator-terraclassic

# Wait for: "Successfully announced validator"
```

### Start Relayer (Optional)

```bash
# Start relayer
docker-compose up -d relayer

# View logs
docker logs -f hpl-relayer
```

---

## 📊 **Monitoring**

### View Logs

```bash
# Validator logs
docker logs hpl-validator-terraclassic --tail 100

# Relayer logs
docker logs hpl-relayer --tail 100
```

### Check Checkpoints in S3

```bash
# List checkpoints
aws s3 ls s3://YOUR-BUCKET-NAME/ --recursive

# Check last checkpoint
aws s3 ls s3://YOUR-BUCKET-NAME/ --recursive | tail -1
```

### Check Balances

```bash
# Terra Classic (hexKey)
curl "https://lcd.terraclassic.community/cosmos/bank/v1beta1/balances/YOUR_TERRA_ADDRESS"

# BSC (KMS)
cast balance YOUR_BSC_ADDRESS --rpc-url https://bsc.drpc.org

# Ethereum (KMS)
cast balance YOUR_ETH_ADDRESS --rpc-url https://eth.llamarpc.com

# Solana (KMS) - check in explorer or relayer logs
```

---

## 🚨 **Troubleshooting**

### Error: "AccessDenied" on S3

**Cause:** Incorrect bucket policy or invalid AWS credentials

**Solution:**
1. Check bucket policy in AWS Console
2. Check `.env` with correct credentials
3. Check IAM user ARN in policy

### Error: "AccessDeniedException" when creating KMS key

**Cause:** IAM user doesn't have permission to create KMS keys.

**Solution:**
1. Go to AWS IAM Console: https://us-east-1.console.aws.amazon.com/iamv2/home
2. Click **"Users"** → Select your user
3. Click **"Add permissions"** → **"Create inline policy"**
4. Click **"JSON"** tab and paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetPublicKey",
        "kms:Sign",
        "kms:CreateAlias",
        "kms:ListAliases",
        "kms:ListKeys"
      ],
      "Resource": "*"
    }
  ]
}
```

5. Name: `HyperlaneKMSPolicy`
6. Click **"Create policy"**
7. Try creating the key again:

```bash
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1
```

**See STEP 1.5 in this guide for complete IAM policy setup.**

### Error: "NotFoundException: Invalid keyId" when creating alias

**Cause:** Using Access Key ID (`AKIA...`) instead of KMS Key ID (UUID format).

**Solution:**

1. **Create the KMS key:**
```bash
aws kms create-key \
  --key-spec ECC_SECG_P256K1 \
  --key-usage SIGN_VERIFY \
  --region us-east-1
```

2. **Example response (with fictional data):**
```json
{
    "KeyMetadata": {
        "AWSAccountId": "123456789012",
        "KeyId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "Arn": "arn:aws:kms:us-east-1:123456789012:key/a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "CreationDate": "2025-12-03T13:08:15.991000-03:00",
        "Enabled": true,
        "Description": "",
        "KeyUsage": "SIGN_VERIFY",
        "KeyState": "Enabled",
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "ECC_SECG_P256K1",
        "KeySpec": "ECC_SECG_P256K1",
        "SigningAlgorithms": [
            "ECDSA_SHA_256"
        ],
        "MultiRegion": false
    }
}
```

3. **Copy the `KeyId` from the response** (in this example: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

4. **Use that Key ID (NOT your Access Key ID) to create the alias:**
```bash
# ✅ CORRECT: Using Key ID from create-key response
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-solana \
  --target-key-id a1b2c3d4-e5f6-7890-abcd-ef1234567890 \
  --region us-east-1

# Success! No output means it worked.
```

**❌ WRONG Example (what NOT to do):**
```bash
# ❌ This will fail with "Invalid keyId"
aws kms create-alias \
  --alias-name alias/hyperlane-relayer-signer-solana \
  --target-key-id AKIAWK73T2L43T4Y46WJ \
  --region us-east-1
```

**⚠️ Remember:**
- ❌ **Access Key ID** (`AKIA...`) = For AWS authentication (in `.env` file)
- ✅ **KMS Key ID** (UUID like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`) = For KMS key operations (create-alias, sign, etc.)

### Error: "InvalidSignatureException" on KMS

**Cause:** KMS key doesn't exist or no permissions

**Solution:**
```bash
# Check if key exists
aws kms describe-key --key-id alias/hyperlane-relayer-signer-bsc --region us-east-1

# Check permissions
aws kms get-key-policy \
  --key-id alias/hyperlane-relayer-signer-bsc \
  --policy-name default \
  --region us-east-1
```

### Container won't start

```bash
# View complete logs
docker logs hpl-validator-terraclassic

# Restart
docker-compose down
docker-compose up -d validator-terraclassic
```

---

## 📚 **References**

- [Hyperlane Validator Setup](https://docs.hyperlane.xyz/docs/operate/validators/run-validators)
- [AWS KMS Keys](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys)
- [AWS S3 Bucket Setup](https://docs.hyperlane.xyz/docs/operate/validators/validator-signatures-aws)
- [IAM User Creation](https://docs.hyperlane.xyz/docs/operate/set-up-agent-keys#create-an-iam-user)

---

## 📝 **Summary**

### ✅ For Validator (Terra Classic):

1. Create IAM User
2. Create S3 Bucket
3. Use **hexKey** (local private key)
4. ❌ **DO NOT use AWS KMS**

### ✅ For Relayer (Optional):

1. Create KMS key for **BSC/Ethereum/Solana** (EVM/Sealevel)
2. Use **hexKey** for **Terra Classic** (Cosmos)
3. Configure all chains in `relayer.json`

---

**🎯 Next step:** Follow [`QUICKSTART.md`](QUICKSTART.md) to run!
