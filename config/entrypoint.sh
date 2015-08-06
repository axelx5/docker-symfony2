#!/bin/bash -e
#
red='\e[0;31m'
NC='\e[0m' # No Color
echo -e "${red}Bienvenidos al contenedor para PHP+NGINX+MARIADB${NC}\n"

echo -e 'Configurando MariaDB\n'

# Iniciar MariaDB

# Parar si hay algun error
set -e

#Si es la primera vez ejecutamos first_run sino normal_run que no hace nada jajaj
if [[ -e /firstrun ]]; then
  source /scripts/first_run.sh
else
  source /scripts/normal_run.sh
fi

wait_for_mysql_and_run_post_start_action() {
  # Esperamos a que se inicie el servicio de mariadb =)
  while [[ ! -e /run/mysqld/mysqld.sock ]] ; do
      inotifywait -q -e create /run/mysqld/ >> /dev/null
  done

  #Ejecutamos lo que querramos luego
  post_start_action
}

#Si no hay nada en /var/www no montamos la app de symfony
if [ ! -d /var/www ]; then
    echo -e 'No se encuentra nada en /var/www , montaste la carpeta de symfony ?\n'
    exit 1;
fi

cd /var/www

#Si no esta la carpeta vendor intalamos symfony
if [ ! -d vendor ]; then
	echo -e 'Instalando symfony con composer\n'
    composer install
fi

#Dejo un hook para que puedan hacer lo que quieran definiendo un script init.sh
if [ -f ./init.sh ]; then
    ./init.sh
fi

echo -e 'Configurando y habilitando servicios\n'

#Antes de iniciar mysql(maria)
pre_start_action 

exec service ssh start & service php5-fpm start & service nginx start & wait_for_mysql_and_run_post_start_action &

echo -e "Servicios web ok , iniciando MariaDB\n"
exec /usr/bin/mysqld_safe
