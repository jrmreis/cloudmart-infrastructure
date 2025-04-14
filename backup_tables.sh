#!/bin/bash
# Script to backup all DynamoDB tables

# Set variables
BACKUP_DIR="dynamodb_backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1"  # Default region if not configured
fi

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

echo "Starting DynamoDB backup process - $(date)"
echo "Using AWS region: $AWS_REGION"
echo "Backup will be stored in: $BACKUP_DIR/$DATE"

# Get list of all tables
TABLES=$(aws dynamodb list-tables --region $AWS_REGION --output text --query 'TableNames[]')

if [ -z "$TABLES" ]; then
  echo "No DynamoDB tables found in region $AWS_REGION"
  exit 1
fi

# Create a master backup record
echo "Tables backed up on $(date)" > $BACKUP_DIR/$DATE/backup_info.txt
echo "AWS Region: $AWS_REGION" >> $BACKUP_DIR/$DATE/backup_info.txt
echo "----------------------------" >> $BACKUP_DIR/$DATE/backup_info.txt

# Backup each table
for TABLE in $TABLES; do
  echo "Backing up table: $TABLE"
  
  # Option 1: Create AWS native backup (recommended for restoration)
  BACKUP_ARN=$(aws dynamodb create-backup \
    --table-name $TABLE \
    --backup-name "${TABLE}_${DATE}" \
    --region $AWS_REGION \
    --output text \
    --query 'BackupDetails.BackupArn')
  
  echo "$TABLE backup ARN: $BACKUP_ARN" >> $BACKUP_DIR/$DATE/backup_info.txt
  
  # Option 2: Export data as JSON (useful for data portability)
  echo "Exporting table data to JSON: $TABLE"
  aws dynamodb scan \
    --table-name $TABLE \
    --region $AWS_REGION > $BACKUP_DIR/$DATE/$TABLE.json
  
  # Option 3: Save table structure/schema
  echo "Saving table structure: $TABLE"
  aws dynamodb describe-table \
    --table-name $TABLE \
    --region $AWS_REGION > $BACKUP_DIR/$DATE/${TABLE}_schema.json
  
  echo "Backup completed for table: $TABLE"
  echo ""
done

# Create a compressed archive of all exported data
echo "Creating compressed archive of all backups..."
tar -czf $BACKUP_DIR/dynamodb_backup_$DATE.tar.gz -C $BACKUP_DIR $DATE

echo "Backup process completed successfully!"
echo "Backup files location: $BACKUP_DIR/dynamodb_backup_$DATE.tar.gz"
echo "AWS Native backups are also stored in AWS and can be viewed in the DynamoDB console"
