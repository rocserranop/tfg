# Definimos el proveedor y la REGION de AWS donde queremos desplegar
provider "aws" {
	region = "eu-south-2"
	access_key = var.my_access_key
	secret_key = var.my_secret_key
}

# Definimos una VPC (red privada virtual) para nuestro despliegue
resource "aws_vpc" "this" {
  cidr_block = "10.100.0.0/16"
  tags = {
    Name = "tfg-vpc"
  }
}
# Definimos subredes públicas
resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr_publico1
  availability_zone = "eu-south-2a"

  tags = {
    Name = "tfg-publica-1"
  }
}
resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr_publico2
  availability_zone = "eu-south-2b"

  tags = {
    Name = "tfg-publica-2"
  }
}
# Definimos subredes privadas
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr_privado1
  availability_zone = "eu-south-2a"

  tags = {
    Name = "tfg-privada-1"
  }
}
resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.cidr_privado2
  availability_zone = "eu-south-2b"

  tags = {
    Name = "tfg-privada-2"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "tfg-igw"
  }
}

# elastic ip
resource "aws_eip" "eip" {
  domain = "vpc"
}

#nat gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "tfg-nat"
  }
}

# route table pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# route table privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Asociar las route table 
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

# security group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}


#BAse de datos subnet
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}

# BAse de datos security group
resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/16"]
  }

  tags = {
    Name = "RDS Security Group"
  }
  
}



# Generar una clave privada nueva
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
}

# Generar un par de claves con la clave generada anteriormente
resource "aws_key_pair" "tfg-key" {
  key_name   = "tfg-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Guardar el par de claves
resource "null_resource" "save_key_pair"  {
	provisioner "local-exec" {
	    command = "echo  ${tls_private_key.my_key.private_key_pem} > mykey.pem"
  	}
}



#Creación EC2

resource "aws_instance" "bbdd" {
  ami                         = var.db_ami
  instance_type               = var.db_instance_type
  
 
  tags = {
    Name = var.db_name
  }
  key_name                    = "tfg-key"
  subnet_id                   = aws_subnet.private1.id
  security_groups             = [aws_security_group.rds_security_group.id]
  private_ip                  = var.db_local_ip
  associate_public_ip_address = true 
  
 
user_data=<<-EOF
#!/bin/bash
echo "${var.db_tag_ec2}" > /etc/hostname && hostname -F /etc/hostname
sudo apt update -y
sudo apt upgrade -y

sudo apt install mysql-server -y
sudo sed -i '/^bind.address/s/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql

sudo mysql -u root -e "CREATE USER 'wpuser'@'%' IDENTIFIED BY 'password';"
sudo mysql -u root -e "CREATE DATABASE wpbd;"
sudo mysql -u root -e "use wpbd; GRANT ALL PRIVILEGES ON *.* TO 'wpuser'@'%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

EOF

}


resource "aws_instance" "wordpress" {
  ami                         = var.front_ami
  instance_type               = var.front_instance_type
  tags = {
    Name = var.front_name
  }
  key_name                    = "tfg-key"
  subnet_id                   = aws_subnet.public1.id
  security_groups             = [aws_security_group.allow_ssh.id]
  private_ip                  = var.front_local_ip
  associate_public_ip_address = true  

user_data=<<-EOF
#!/bin/bash
echo "${var.front_tag_ec2}" > /etc/hostname && hostname -F /etc/hostname
sudo apt update -y
sudo apt upgrade -y

sudo apt install apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip -y

sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
sudo echo "<VirtualHost *:80>
            DocumentRoot /srv/www/wordpress
          <Directory /srv/www/wordpress>
            Options FollowSymLinks
            AllowOverride Limit Options FileInfo
            DirectoryIndex index.php
            Require all granted
           </Directory>
           <Directory /srv/www/wordpress/wp-content>
            Options FollowSymLinks
            Require all granted
           </Directory>
           </VirtualHost>" > /etc/apache2/sites-available/wordpress.conf
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default

sudo echo "<?php
 define( 'DB_NAME', 'wpbd' );
 define( 'DB_USER', 'wpuser' );
 define( 'DB_PASSWORD', 'password' );

 define( 'DB_HOST', '${var.db_local_ip}' );

 define( 'DB_CHARSET', 'utf8' );
 define( 'DB_COLLATE', '' );
 \$table_prefix = 'wp_';
 define( 'WP_DEBUG', false );
 if ( ! defined( 'ABSPATH' ) ) {
	 define( 'ABSPATH', __DIR__ . '/' );
 }
 require_once ABSPATH . 'wp-settings.php';" >/srv/www/wordpress/wp-config.php

sudo systemctl restart apache2

sudo sleep 180

sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

sudo wp core install --path=/srv/www/wordpress --url='www.test-tfg.com' --title='Aplicación Web para el TFG' --admin_user=supervisor --admin_email=pablo.roc@gmail.com --admin_password=password
sudo wp post create --path=/srv/www/wordpress --post_type=post --post_title='Post generado durante la creación del sitio' --post_content='Contenido del post Contenido del post Contenido del post Contenido del post Contenido del post Contenido del post '

EOF

depends_on = [ aws_instance.bbdd ]
}

