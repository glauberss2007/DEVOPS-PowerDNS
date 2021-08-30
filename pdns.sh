#! /bin/sh

yum -y upgrade;

# Instalar banco de dados
dnf install httpd mariadb-server -y;

# EPEL e REMI
yum -y install epel-release;
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm;
yum -y install yum-utils;
yum-config-manager --enable remi-php72;

# BANCO DE DADOS
yum -y install mariadb mariadb-server;
systemctl start mariadb;
systemctl enable mariadb;

mysql_secure_installation
mysql -u root -p -B -N -e "create database powerdns;
grant all privileges on powerdns.* to pdns@localhost identified by 'pdnspassword2018';
flush privileges;
use powerdns;
 
 CREATE TABLE domains (
   id                    INT AUTO_INCREMENT,
   name                  VARCHAR(255) NOT NULL,
   master                VARCHAR(128) DEFAULT NULL,
   last_check            INT DEFAULT NULL,
   type                  VARCHAR(6) NOT NULL,
   notified_serial       INT DEFAULT NULL,
   account               VARCHAR(40) DEFAULT NULL,
   PRIMARY KEY (id)
 ) Engine=InnoDB;
 
 CREATE UNIQUE INDEX name_index ON domains(name);
 
 CREATE TABLE records (
   id                    BIGINT AUTO_INCREMENT,
   domain_id             INT DEFAULT NULL,
   name                  VARCHAR(255) DEFAULT NULL,
   type                  VARCHAR(10) DEFAULT NULL,
   content               VARCHAR(64000) DEFAULT NULL,
   ttl                   INT DEFAULT NULL,
   prio                  INT DEFAULT NULL,
   change_date           INT DEFAULT NULL,
   disabled              TINYINT(1) DEFAULT 0,
   ordername             VARCHAR(255) BINARY DEFAULT NULL,
   auth                  TINYINT(1) DEFAULT 1,
   PRIMARY KEY (id)
 ) Engine=InnoDB;
 
 CREATE INDEX nametype_index ON records(name,type);
 CREATE INDEX domain_id ON records(domain_id);
 CREATE INDEX recordorder ON records (domain_id, ordername);
 
 
 CREATE TABLE supermasters (
   ip                    VARCHAR(64) NOT NULL,
   nameserver            VARCHAR(255) NOT NULL,
   account               VARCHAR(40) NOT NULL,
   PRIMARY KEY (ip, nameserver)
 ) Engine=InnoDB;
 
 
 CREATE TABLE comments (
   id                    INT AUTO_INCREMENT,
   domain_id             INT NOT NULL,
   name                  VARCHAR(255) NOT NULL,
   type                  VARCHAR(10) NOT NULL,
   modified_at           INT NOT NULL,
   account               VARCHAR(40) NOT NULL,
   comment               VARCHAR(64000) NOT NULL,
   PRIMARY KEY (id)
 ) Engine=InnoDB;
 
 CREATE INDEX comments_domain_id_idx ON comments (domain_id);
 CREATE INDEX comments_name_type_idx ON comments (name, type);
 CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);
 
 CREATE TABLE domainmetadata (
   id                    INT AUTO_INCREMENT,
   domain_id             INT NOT NULL,
   kind                  VARCHAR(32),
   content               TEXT,
   PRIMARY KEY (id)
 ) Engine=InnoDB;
 
 CREATE INDEX domainmetadata_idx ON domainmetadata (domain_id, kind);
 
 CREATE TABLE cryptokeys (
   id                    INT AUTO_INCREMENT,
   domain_id             INT NOT NULL,
   flags                 INT NOT NULL,
   active                BOOL,
   content               TEXT,
   PRIMARY KEY(id)
 ) Engine=InnoDB;
 
 CREATE INDEX domainidindex ON cryptokeys(domain_id);
 
 CREATE TABLE tsigkeys (
   id                    INT AUTO_INCREMENT,
   name                  VARCHAR(255),
   algorithm             VARCHAR(50),
   secret                VARCHAR(255),
   PRIMARY KEY (id)
 ) Engine=InnoDB;
 
 CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);
 
 quit;

# Instalar o PowerDNS
yum -y install pdns pdns-backend-mysql bind-utils
cd /etc/pdns/
vim pdns.conf
#By default, PowerDNS is using 'bind' as the backend. So, type comment '#' in the front of 'launch=bind' configuration and paste the MySQL backend configuration as below.
#set launch=gmysql
#set gmysql-host=localhost
#set gmysql-user=pdns
#set gmysql-password=pdnspassword2018
#set gmysql-dbname=powerdns

systemctl start pdns;
systemctl enable pdns;

firewall-cmd --add-service=dns --permanent;
firewall-cmd --reload;

netstat -tap | grep pdns
netstat -tulpn | grep 53
dig @10.9.9.10
#As a result, you will get the pdns service is up and running on port 53 and get the response from the PowerDNS server.

Check PowerDNS status;

# Instalação Poweradmin
yum -y install httpd php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mhash gettext
yum -y install php-pear-DB php-pear-MDB2-Driver-mysqli
systemctl start httpd
systemctl enable httpd


cd /var/www/html/
 wget http://downloads.sourceforge.net/project/poweradmin/poweradmin-2.1.7.tgz
Extract the poweradmin compressed file and rename it.

tar xvf poweradmin-2.1.7.tgz
 mv poweradmin-2.1.7/ poweradmin/
After that, add the HTTP and HTTPS protocols to the firewall.

firewall-cmd --add-service={http,https} --permanent
 firewall-cmd --reload
And we're ready for the poweradmin post-installation.

Step 5 - Poweradmin Post-Installation
Open your web browser and type the server IP address plus the /poweradmin/install/ path URL for the installation. Mine is:

http://10.9.9.10/poweradmin/install/

Choose your preferred language and click the 'Go to Step 2' button.

PowerAdmin setup 1

Now just click the 'Go to Step 3' button.

PowerAdmin setup 2

And you will be displayed for the database configuration. Type the PowerDNS database details that we've created and the admin password for PowerDNS.

PowerAdmin database setup

Click the 'Go to Step 4' button.

After that, you will need to create a new user will limited right privileges. Type the details as the following and change the user, password, etc with your own.

PowerAdmin user setup

Now click 'Go to Step 5' button.

And you will be shown the page as below.

PowerAdmin setup finished

Open again your terminal server, log in with the root user and password. Then run the MySQL queries as on the page.

mysql -u root -p
 PASSWORD
 
 GRANT SELECT, INSERT, UPDATE, DELETE
 ON powerdns.*
 TO 'hakase'@'localhost'
 IDENTIFIED BY 'hakase-labs123';
Mysql commands

Now back to the web browser and click the 'Go to Step 6' button.

And you will be shown the page as below.

Installation step 6

The installer was unable to create a new configuration '../inc/config.inc.php'. So, we need to create it manually.

Back to the terminal server, go to the '/var/www/html/poweradmin' directory and create a new configuration file 'inc/config.inc.php'.

cd /var/www/html/poweradmin
 vim inc/config.inc.php
Now paste the PHP script on the page into it.

<?php

$db_host                = 'localhost';
$db_user                = 'hakase';
$db_pass                = 'hakase-labs123';
$db_name                = 'powerdns';
$db_type                = 'mysql';
$db_layer               = 'PDO';

$session_key            = 'xTNxUiXIu320Z@N=uetwJeD2#uApgO)2Ekj+S#oN1Khhoj';

$iface_lang             = 'en_EN';

$dns_hostmaster         = 'server.hakase-labs.io';
$dns_ns1                = 'ns1.hakase-labs.io';
$dns_ns2                = 'ns2.hakase-labs.io';
Save and close, then back to the browser and click the button.

Database configuration file

And the installation is complete.

Optionally:

If you want to support for the URLs used by other Dynamic providers, copy the htaccess file.

cd /var/www/html/poweradmin
 cp install/htaccess.dist .htaccess
After that, you MUST remove the 'install' directory.

rm -rf /var/www/html/poweradmin/install
.htaccess protection

Back again to your web browser and log in to the Poweradmin dashboard using the URL as below.

http://10.9.9.10/poweradmin/

Log in with the default user 'admin' and the password, click the 'Go' button.

PowerAdmin Login

And as a result, you will be shown the Poweradmin dashboard and the installation is finished.

PowerAdmin Dashboard

Step 6 - Create Sample Zone and DNS Records
At this stage, we're going test the PowerDNS and Poweradmin installation by creating a new DNS zone for a domain called 'emma.io'.

On the Poweradmin dashboard, click the 'Add master zone' menu.

Add master zone

Set the zone name with the domain name 'emaa.io' and click 'Add zone' button.

Add DNS Zone in PowerAdmin

Click the 'List zones' menu to get all available zone. And click the 'edit' button for the zone 'emma.io'.

Set Zone name

Click the 'List zones' menu to get all available zone. And click the 'edit' button for the zone 'emma.io'.

List zones

Now click the 'Add record' button and we successfully add the DNS zone and DNS record for the domain named 'emma.io'.

Next, we're going to test the domain 'emma.io' using a 'dig' DNS utility command.

Check the name server or ns record of the domain 'emma.io'.

dig NS emma.io @10.9.9.10
Check zone with dig command

Check the A DNS record of the domain 'emma.io'.

dig A emma.io @10.9.9.10
dig command result

And you will be displayed the domain 'emma.io' has a nameserver from our DNS server 'ns1.hakase-labs.io', and the 'A' of that domain name is match with our configuration on the top with server IP address '10.9.9.11'.

Finally, the installation and configuration of PowerDNS and Poweradmin on CentOS 7 have been completed successfully.
