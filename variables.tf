# las claves de acceso están almacenadas en un fichero externo "secret.tfvars" y se leen desde allí
# el fichero externo no está dentro de los ficheros subidos a Git
variable "my_access_key" {
  description = "Access-key-for-AWS"
  default = "no_access_key_value_found"
}

variable "my_secret_key" {
  description = "Secret-key-for-AWS"
  default = "no_secret_key_value_found"
}
variable "my_new_passwd" {
  description = "Secret-password-for-mysql-ec2"
  default = "no_secret_key_value_found"
}
# las variables a continuación definen el tamaño de las máquinas en este despliegue, la imagen, el nombre del front....check "
variable "front_ami" {
  description = "Imagen de sistema operativo para el front"
  default = "ami-0a16a33f6ac6b0ed7"  #ubuntu linux
}

variable "front_instance_type" {
  description = "Tipo de EC2 para el front"
  default = "t3.micro"
}

variable "front_tag_ec2" {
  description = "Etiqueta de frontal"
  default = "www.dominio1234.com"
}

variable "front_name" {
  description = "Etiqueta Name para la EC2"
  default = "frontal"
}

variable "db_ami" {
  description = "Imagen de sistema operativo para la base de datos"
  default = "ami-0a16a33f6ac6b0ed7"  #ubuntu linux
}

variable "db_instance_type" {
  description = "Tipo de EC2 para la base de datos"
  default = "t3.micro"
}

variable "db_tag_ec2" {
  description = "Etiqueta de database"
  default = "www.dominio1234.com"
}

variable "db_name" {
  description = "Etiqueta Name para la EC2 de la base de datos"
  default = "database"
}


# Redes


variable "cidr_publico1"{
    description ="'CIDR de la red pública en la 1a AZ"
    default = "10.100.1.0/24"
}

variable "cidr_publico2"{
    description ="'CIDR de la red pública en la 2º AZ"
    default = "10.100.2.0/24"
}

variable "cidr_privado1"{
    description ="'CIDR de la red privada en la 1a AZ"
    default = "10.100.3.0/24"
}

variable "cidr_privado2"{
    description ="'CIDR de la red privada en la 2a AZ"
    default = "10.100.4.0/24"
}

variable "front_local_ip"{
    description ="'IP de la red interna"
    default = "10.100.1.10"
}

variable "db_local_ip" {
  description = "Ip interna de la base de datos"
  default = "10.100.3.100"
}


