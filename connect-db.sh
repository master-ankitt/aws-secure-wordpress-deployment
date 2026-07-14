#!/bin/bash
secrets=$(aws secretsmanager get-secret-value --secret-id "rds!db-3b252d74-a303-4765-ac08-bee42ed853c6" --query SecretString --output text)
username=$(echo "$secrets" | jq -r '.username')
password=$(echo "$secrets" | jq -r '.password')
mysql -h my-db.cf8mqms8omnt.ap-south-1.rds.amazonaws.com -u "$username" -p"$password" -P 3306
