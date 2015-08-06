USER=admin
PASS=${PASS:-$(pwgen -s -1 16)}

pre_start_action() {
  echo -e "MARIADB_USER=$USER"
  echo -e "MARIADB_PASS=$PASS"
  PASS_ECHO=$PASS
}

post_start_action() {
  DB_MAINT_PASS=$(cat /etc/mysql/debian.cnf | grep -m 1 "password\s*=\s*"| sed 's/^password\s*=\s*//')
  mysql -u root -e \
      "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DB_MAINT_PASS';"

  
  # Create the superuser.
  mysql -u root <<-EOF
      DELETE FROM mysql.user WHERE user = '$USER';
      FLUSH PRIVILEGES;
      CREATE USER '$USER'@'localhost' IDENTIFIED BY '$PASS';
      GRANT ALL PRIVILEGES ON *.* TO '$USER'@'localhost' WITH GRANT OPTION;
      CREATE USER '$USER'@'%' IDENTIFIED BY '$PASS';
      GRANT ALL PRIVILEGES ON *.* TO '$USER'@'%' WITH GRANT OPTION;
EOF

  set_root_ssh_password
  rm /firstrun
}

set_root_ssh_password() {
  #!/bin/bash
  PASS=${ROOT_PASS:-$(pwgen -s 12 1)}
  _word=$( [ ${ROOT_PASS} ] && echo -e "preset" || echo -e "random" )

  echo -e "=> Configurando un ${_word} password para el usuario root"
  echo -e "root:$PASS" | chpasswd


  touch /.root_pw_set
  echo -e "===============================MariaDB====================================="
  echo -e "Usuario de maria DB:"
  echo -e ""
  echo -e "    MARIADB_USER=$USER"
  echo -e "    MARIADB_PASS=$PASS_ECHO"
  echo -e ""
  echo -e "============================================================================"

  echo -e "==============================SSH=========================================="
  echo -e "Ahora se pueden conectar via SSH suando:"
  echo -e ""
  echo -e "    ssh -p <port> root@<host>"
  echo -e "    password del usuario root '$PASS'"
  echo -e ""
  echo -e "Si lo desean pueden cambiar el password desde adentro, es recomendable!"
  echo -e "=========================================================================== \n"


}