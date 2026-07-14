# 🚀 WordPress Deployment on AWS using Amazon RDS, AWS Secrets Manager, IAM Role and EC2

## Project Overview

This project demonstrates how to deploy a WordPress application on AWS using Amazon EC2, Amazon RDS (MySQL), AWS Secrets Manager, IAM Roles, and Apache HTTP Server.

Instead of storing the RDS master password manually, the database credentials are securely managed using AWS Secrets Manager. The EC2 instance accesses the secret through an IAM Role without requiring AWS Access Keys.

The project follows AWS security best practices by separating the web server and database, keeping the database private, and managing sensitive credentials securely.

---

# Project Scenario

A company wants to deploy a secure WordPress website on AWS.

Requirements:

- Launch a WordPress web server.
- Store website data inside Amazon RDS.
- Keep the database private.
- Store database credentials securely.
- Avoid hardcoding AWS credentials.
- Allow EC2 to retrieve secrets securely using an IAM Role.

To achieve this, we use the following AWS services.

```text
                    Internet
                        │
                        ▼
                 Amazon EC2
               (WordPress Server)
                        │
        IAM Role (SecretsManagerReadWrite)
                        │
                        ▼
             AWS Secrets Manager
                        │
                        ▼
              Amazon RDS (MySQL)
```

---

# AWS Services Used

| AWS Service | Purpose |
|-------------|---------|
| Amazon EC2 | Host WordPress Application |
| Amazon RDS | MySQL Database |
| AWS Secrets Manager | Securely Store Database Credentials |
| AWS IAM | Authorization and Access Management |
| Amazon VPC | Network Isolation |
| Security Groups | Firewall Rules |
| Apache HTTP Server | Web Server |
| PHP | Execute WordPress |
| MariaDB Client | Connect EC2 to RDS |

---

# Architecture Diagram

```text
                     Users
                        │
                        ▼
                 Public Internet
                        │
                        ▼
               Amazon EC2 Instance
             (Apache + PHP + WordPress)
                        │
          IAM Role (SecretsManagerReadWrite)
                        │
                        ▼
             AWS Secrets Manager
                        │
                        ▼
              Amazon RDS (Private)
```

---

# Deployment Phases

- Phase 1 : Create Amazon RDS Database
- Phase 2 : Store Credentials in AWS Secrets Manager
- Phase 3 : Create IAM Role
- Phase 4 : Launch Amazon EC2 Instance
- Phase 5 : Configure Database
- Phase 6 : Install Apache, PHP and WordPress
- Phase 7 : Configure WordPress
- Phase 8 : Launch Website
- Phase 9 : Complete WordPress Installation

---

# Phase 1 : Create Amazon RDS Database

In this phase, we create a private MySQL database that will store all WordPress data such as posts, users, themes, plugins, comments, and settings.

---

## Step 1 : Create Database Security Group

Navigate:

```text
VPC
   ↓
Security Groups
   ↓
Create Security Group
```

Security Group Name : database-sg

---

### Inbound Rules

Allow MySQL traffic only from the web server.

| Type | Source |
|------|--------|
| MYSQL/Aurora | wp-webserver-sg |
| MYSQL/Aurora | <EC2-Private-IP>/32 |

> **Note:** Never allow MySQL access from `0.0.0.0/0` in production.

---

## Step 2 : Create Amazon RDS

Navigate

```text
Amazon RDS
      ↓
Databases
      ↓
Create Database
```

---

### Engine Configuration

```text
Engine Type              : MySQL
Database Creation Method : Full Configuration
Templates                : Free Tier [ Choose another template if required. ]
Availability             : Single-AZ DB Instance
Engine Version           : MySQL 8.4.9
DB Instance Identifier   : my-db
Master Username          : admin
Credentials Management   : Managed in AWS Secrets Manager (Recommended)
Database Authentication  : Password Authentication
Instance Class           : Burstable Classes
Instance Type            : db.t4g.micro
Storage                  : General Purpose SSD (gp2)
Allocated Storage        : 20 GiB
Compute Resource         : Don't connect to an EC2 Compute Resource [ We will manually configure connectivity later. ]
Network Settings         : VPC Default
Public Access            : No
Security Group           : Choose Existing ( Select - database-sg )
Database Port            : 3306
--> Click - Create Database
```
> **Note:** If you want AWS to automatically configure the database with recommended settings, choose **Easy Create**.
> **Note:** All remaining settings can be left as default unless your project requires additional customization.
---

# Phase 2 : AWS Secrets Manager

During the RDS creation process, we selected **Managed in AWS Secrets Manager** for the master credentials.

AWS automatically creates and manages a secret containing the RDS master username and password.

This eliminates the need to manually store database credentials in configuration files or scripts.

---

## Verify the Secret

Navigate

```text
AWS Console
    ↓
Secrets Manager
    ↓
Secrets
```

You should see a secret similar to:

```text
rds!db-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Open the secret.

You will find information similar to:

```json
{
  "engine": "mysql",
  "host": "my-db.cf8mqms8omnt.ap-south-1.rds.amazonaws.com",
  "username": "admin",
  "password": "****************",
  "dbname": "my-db",
  "port": 3306
}
```

---

## Secret Rotation

AWS Secrets Manager also provides automatic password rotation.

Navigate

```text
Secrets Manager
      ↓
Your Secret
      ↓
Rotation Configuration
```

You can enable automatic password rotation according to your organization's security policy.

> **Note:** For this project, rotation is left disabled.

---

# Phase 3 : Create IAM Role

In this phase, we create an IAM Role that allows the EC2 instance to securely retrieve secrets from AWS Secrets Manager.

This removes the need to configure AWS Access Keys manually on the server.

---

## Create IAM Role

Navigate

```text
AWS Console
     ↓
IAM
     ↓
Roles
     ↓
Create Role
```

---

### Create Role

```text
Trusted Entity     : AWS Service
Service            : EC2
Attach Permissions : SecretsManagerReadWrite
Role Name          : sm-read-write-permission
```

---

# Phase 4 : Launch Amazon EC2 Instance

In this phase, we launch an EC2 instance that will host the WordPress application.

---

## Step 1 : Create Security Group

Navigate

```text
VPC
     ↓
Security Groups
     ↓
Create Security Group
```

Security Group Name :- wp-webserver-sg

### Inbound Rules

| Type | Source |
|------|--------|
| SSH | Anywhere IPv4 |
| HTTP | Anywhere IPv4 |

> **Note:** In production environments, SSH access should be restricted to trusted IP addresses instead of allowing access from anywhere.

---

## Step 2 : Launch EC2

Navigate

```text
Amazon EC2
      ↓
Instances
      ↓
Launch Instance
```

---

### Instance Configuration

```text
Instance Name : wordpress-web
AMI : Amazon Linux 2023
Instance Type : t3.micro
Key Pair : wordpress-key
Network Settings : Use the default VPC.
Choose the existing Security Group : wp-webserver-sg
Click : Launch Instance

** Leave the remaining settings as default.

```

# Attach IAM Role to EC2

After the instance is running,

Navigate

```text
EC2
     ↓
Instances
     ↓
Select Instance
     ↓
Actions
     ↓
Security
     ↓
Modify IAM Role
```

Select

```text
sm-read-write-permission
```

Click

```text
Update IAM Role
```

---

# Connect to EC2

```bash
ssh -i wordpress-key.pem ec2-user@<PUBLIC-IP>
```

---

# Install MariaDB Client

Since this project uses **Amazon Linux 2023**, install the MariaDB client.

```bash
sudo dnf install mariadb105 jq -y
```

Verify installation.

```bash
mysql --version
```

---

# Verify IAM Role

Check whether the EC2 instance can access AWS services without configuring AWS Access Keys.

Run

```bash
aws sts get-caller-identity
```

Expected Output

```json
{
    "Account":"123456789012",
    "Arn":"arn:aws:sts::123456789012:assumed-role/sm-read-write-permission/i-xxxxxxxx",
    "UserId":"xxxxxxxx"
}
```

This confirms that the IAM Role has been attached successfully.

---

# Retrieve Database Credentials from Secrets Manager

Instead of manually typing the RDS username and password every time, create a script that automatically retrieves the credentials from AWS Secrets Manager.

Create a new script.

```bash
vim connect-db.sh
```

Paste the following script.

```bash
#!/bin/bash
secrets=$(aws secretsmanager get-secret-value --secret-id "rds!db-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --query SecretString --output text)
username=$(echo "$secrets" | jq -r '.username')
password=$(echo "$secrets" | jq -r '.password')
mysql -h my-db.cf8mqms8omnt.ap-south-1.rds.amazonaws.com -u "$username" -p"$password" -P 3306

```
Save the file.

Make it executable.

```bash
chmod +x connect-db.sh
```

Run the script.

```bash
./connect-db.sh
```

If everything is configured correctly, you should be connected to the MySQL database.

---

# Create WordPress Database

Execute the following SQL commands.

```sql
CREATE DATABASE wordpress;
CREATE USER 'wordpressuser' IDENTIFIED BY 'Ankit123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'%';
FLUSH PRIVILEGES;
exit;
```
---

> **Best Practice:** Never use the RDS master (`admin`) account for your application. Create a dedicated database user (such as `wordpressuser`) and grant only the permissions required by the application. This follows the **Principle of Least Privilege**, reducing the impact of a compromised application account.

---
# Phase 5 : Install Apache, PHP and WordPress

In this phase, we configure the EC2 instance as a WordPress web server by installing Apache HTTP Server, PHP, and the required PHP extensions.

---

# Install Apache HTTP Server

Install Apache.

```bash
sudo dnf install -y httpd
```

Start the Apache service.

```bash
sudo systemctl start httpd
```

Enable Apache to start automatically after every reboot.

```bash
sudo systemctl enable httpd
```

Verify the service.

```bash
sudo systemctl status httpd
```

Expected Output

```text
Active: active (running)
```

---

# Install PHP and Required Extensions

Since this project uses **Amazon Linux 2023**, install PHP and all required extensions.

```bash
sudo dnf install -y php php-cli php-fpm php-mysqlnd php-gd php-mbstring php-xml php-json php-curl php-zip mariadb105
```

Verify PHP installation.

```bash
php -v
```

Example Output

```text
PHP 8.x.x
```

---

# Download WordPress

Move to the home directory.

```bash
cd ~
```

Download the latest version of WordPress.

```bash
wget https://wordpress.org/latest.tar.gz
```

Extract the archive.

```bash
tar -xzf latest.tar.gz
```

Navigate into the WordPress directory.

```bash
cd wordpress
```

Verify the files.

```bash
ls
```

---

# Create WordPress Configuration File

Create a copy of the sample configuration file.

```bash
cp wp-config-sample.php wp-config.php
```

Open the configuration file.

```bash
vim wp-config.php
```

---

# Configure Database Settings

Locate the following lines.

```php
define('DB_NAME', 'database_name_here');

define('DB_USER', 'username_here');

define('DB_PASSWORD', 'password_here');

define('DB_HOST', 'localhost');
```

Replace them with your own database information.

```php
define('DB_NAME', 'wordpress');

define('DB_USER', 'wordpressuser');

define('DB_PASSWORD', 'Ankit123');

define('DB_HOST', 'my-db.cf8mqms8omnt.ap-south-1.rds.amazonaws.com');
```

Save the file.

---

# Generate WordPress Security Keys

Open the following URL in your browser.

```text
https://api.wordpress.org/secret-key/1.1/salt/
```

WordPress automatically generates eight unique authentication keys.

Example

```php
define('AUTH_KEY',         'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('SECURE_AUTH_KEY',  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('LOGGED_IN_KEY',    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('NONCE_KEY',        'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('AUTH_SALT',        'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('SECURE_AUTH_SALT', 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('LOGGED_IN_SALT',   'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

define('NONCE_SALT',       'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
```

---

# Replace Default Security Keys

Inside **wp-config.php**, locate the default values.

```php
define('AUTH_KEY',         'put your unique phrase here');

define('SECURE_AUTH_KEY',  'put your unique phrase here');

define('LOGGED_IN_KEY',    'put your unique phrase here');

define('NONCE_KEY',        'put your unique phrase here');

define('AUTH_SALT',        'put your unique phrase here');

define('SECURE_AUTH_SALT', 'put your unique phrase here');

define('LOGGED_IN_SALT',   'put your unique phrase here');

define('NONCE_SALT',       'put your unique phrase here');
```

Replace all eight lines with the newly generated keys from WordPress.

Save and exit.

---

# Deploy WordPress Files

Return to the home directory.

```bash
cd ..
```

Copy all WordPress files to Apache's web root.

```bash
sudo cp -rf wordpress/* /var/www/html/
```

---

# Set File Permissions

Change ownership to Apache.

```bash
sudo chown -R apache:apache /var/www/html
```

Grant appropriate permissions.

```bash
sudo chmod -R 755 /var/www/html
```

---

# Restart Apache

Restart Apache to apply all changes.

```bash
sudo systemctl restart httpd
```

Verify the service.

```bash
sudo systemctl status httpd
```

Expected Output

```text
Active: active (running)
```

---

# Verify Web Server

Copy the EC2 public IP address.

Example

```text
http://43.xxx.xxx.xxx
```

Open it in your browser.

If everything has been configured correctly, the WordPress installation page will appear.

```text
Welcome to WordPress
```

You are now ready to complete the WordPress installation.

---

# Phase 6 : Complete the WordPress Installation

At this stage, WordPress has successfully connected to the Amazon RDS database.

Since the database is empty, WordPress automatically starts its installation wizard.

Open your browser and visit your EC2 Public IP.

```text
http://<EC2-Public-IP>
```

Example

```text
http://43.xxx.xxx.xxx
```

The following page should appear.

```text
Welcome to WordPress
```

---

# Configure WordPress

Provide the following information as per required.

```text
Site Title    : My WordPress Website
Username      : ankit
Password      : ankit@123 [ Choose a strong password in production. ]
Email Address : your-email@example.com
```

--> Click - Install WordPress

---

If the installation is successful, you will see Success!
WordPress has been installed successfully.

Click

```text
Log In
```

Login using

```text
Username : ankit
Password : sam@123
```

Congratulations 🎉

Your WordPress website is now running successfully.

---

# Repository Structure

```text
wordpress-rds-secretsmanager/
│
├── README.md
├── users_&_security_Understanding
├── Troubleshooting
├── connect-db.sh
├── images/
│   ├── architecture.png
│   ├── rds.png
│   ├── secrets-manager.png
│   ├── iam-role.png
│   ├── ec2.png
│   ├── wordpress-installation.png
│   └── wordpress-dashboard.png
```

---

# Author

**Ankit Choudhary**

DevOps Engineer | AWS Cloud | Linux | Docker | Kubernetes | OpenShift | Terraform | Jenkins | RHCSA | RHCE | DO188 | DO280 | DO380 | DO316

GitHub: https://github.com/master-ankitt

---

⭐ If you found this project helpful, consider giving this repository a **Star** on GitHub.