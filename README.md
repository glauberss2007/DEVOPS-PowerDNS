# oci-vin-dns-env

![image](https://user-images.githubusercontent.com/22028539/131381195-22058b2b-20d3-4f35-a4b4-75b8046ebc7b.png)

Ambiente DNS da OCI de vinhedos

PowerDNS é um servidor de nomes poderoso e de alto desempenho. É uma alternativa ao BIND DNS e pode utilizar MariaDB, MySQL ou Oracle para armazenar registros. O PowerDNS é executado na maioria dos sistemas operacionais baseados em UNIX e é usado para hospedar domínios usando DNSSEC. Ele usa um programa separado chamado PowerDNS Recursor como o servidor DNS de resolução. PowerDNS-Admin é uma interface da web avançada para o PDNS, utilizado para gerenciar zonas e registros por meio de um navegador da web.

Neste projeto utilizamos o terraform para subir os recurses de redes e um script para instalar e configurar o PDNS com MariaDB em SO CentOS 8.

## Topologia final

TODO Desenho da topologia OCI


### Pré-requisitos
CentOS 8 VPS e acesso administrador no servidor.

1. Instalação do servidor web e banco de dados:

dnf install httpd mariadb-server -y
systemctl start httpd
systemctl start mariadb
systemctl enable httpd
systemctl enable mariadb

2. Intalação do PHP e modulos:
````
dnf install http://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
dnf module reset php
dnf module enable php:remi-7.4

````

3. Ative o modulo remi php:
````
dnf module reset php
dnf module enable php:remi-7.4
dnf install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-mbstring php-mcrypt php-mhash gettext php-pear -y
````

4. Habilite o serviço:
````
systemctl start php-fpm
systemctl enable php-fpm
````

5. Configuração do banco de dados e usuario para o PDNS:
````
mysql
create database powerdnsdb;
create user 'powerdns' identified by 'password';
grant all privileges on powerdnsdb.* to 'powerdns'@'localhost' identified by 'password';
flush privileges;
````

6. Script para modelagem do BD:
````
use powerdnsdb;

CREATE TABLE domains (
id INT AUTO_INCREMENT,
name VARCHAR(255) NOT NULL,
master VARCHAR(128) DEFAULT NULL,
last_check INT DEFAULT NULL,
type VARCHAR(6) NOT NULL,
notified_serial INT DEFAULT NULL,
account VARCHAR(40) DEFAULT NULL,
PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX name_index ON domains(name);

CREATE TABLE records (
id BIGINT AUTO_INCREMENT,
domain_id INT DEFAULT NULL,
name VARCHAR(255) DEFAULT NULL,
type VARCHAR(10) DEFAULT NULL,
content VARCHAR(64000) DEFAULT NULL,
ttl INT DEFAULT NULL,
prio INT DEFAULT NULL,
change_date INT DEFAULT NULL,
disabled TINYINT(1) DEFAULT 0,
ordername VARCHAR(255) BINARY DEFAULT NULL,
auth TINYINT(1) DEFAULT 1,
PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX name_index ON domains(name);

CREATE INDEX nametype_index ON records(name,type);

CREATE INDEX domain_id ON records(domain_id);

CREATE INDEX recordorder ON records (domain_id, ordername);

CREATE TABLE supermasters (
ip VARCHAR(64) NOT NULL,
nameserver VARCHAR(255) NOT NULL,
account VARCHAR(40) NOT NULL,
PRIMARY KEY (ip, nameserver)
) Engine=InnoDB;

CREATE TABLE comments (
id INT AUTO_INCREMENT,
domain_id INT NOT NULL,
name VARCHAR(255) NOT NULL,
type VARCHAR(10) NOT NULL,
modified_at INT NOT NULL,
account VARCHAR(40) NOT NULL,
comment VARCHAR(64000) NOT NULL,
PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX comments_domain_id_idx ON comments (domain_id);

CREATE INDEX comments_name_type_idx ON comments (name, type);

CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);

CREATE TABLE domainmetadata (
id INT AUTO_INCREMENT,
domain_id INT NOT NULL,
kind VARCHAR(32),
content TEXT,
PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX domainmetadata_idx ON domainmetadata (domain_id, kind);

CREATE TABLE cryptokeys (
id INT AUTO_INCREMENT,
domain_id INT NOT NULL,
flags INT NOT NULL,
active BOOL,
content TEXT,
PRIMARY KEY(id)
) Engine=InnoDB;

CREATE INDEX domainidindex ON cryptokeys(domain_id);

CREATE TABLE tsigkeys (
id INT AUTO_INCREMENT,
name VARCHAR(255),
algorithm VARCHAR(50),
secret VARCHAR(255),
PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);

show tables;
exit;
````

7. Install powerDNS
````
systemctl disable systemd-resolved
systemctl stop systemd-resolved

ls -lh /etc/resolv.conf
echo "nameserver 8.8.8.8" | tee /etc/resolv.conf

dnf install pdns pdns-backend-mysql bind-utils -y
````
8. Configurar o PDNS para utilizar o mariaDB, remova o ``launch=bind`` e adicione:
````
nano /etc/pdns/pdns.conf

launch=gmysql
gmysql-host=localhost
gmysql-user=powerdns
gmysql-password=password
gmysql-dbname=powerdnsdb

systemctl start pdns
systemctl enable pdns
````

9. Instalar o PowerAdmin:
````
wget http://downloads.sourceforge.net/project/poweradmin/poweradmin-2.1.7.tgz
tar xvf poweradmin-2.1.7.tgz
mv poweradmin-2.1.7 /var/www/html/poweradmin/
chown -R apache:apache /var/www/html/poweradmin

````

10. Acesse a URL http://your-server-ip/poweradmin/install para concluir a instalação pela interface grafica ([GUI conf](https://www.atlantic.net/vps-hosting/how-to-install-powerdns-and-poweradmin-on-centos-8/))

PS: Caso ocorra erro de acesso via URL, pode ser necessario executar o comando ``setenforce 1`` e alterar os campos para, AllowOverride All e Require all granted, em ``/etc/httpd/conf/httpd.conf`` no <Directory "/var/www"> 

Referencias:

https://doc.powerdns.com/

https://www.atlantic.net/vps-hosting/how-to-install-powerdns-and-poweradmin-on-centos-8/
