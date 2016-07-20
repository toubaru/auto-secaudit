FROM tutum/lamp:latest

# Add database setup script
#COPY ./files/create_table.sql /docker-entrypoint-initdb.d/create_table.sql
COPY ./files/create_table.sql /create_table.sql
COPY ./files/charset.cnf /etc/mysql/conf.d/charset.cnf
RUN chmod 644 /etc/mysql/conf.d/charset.cnf

# Add MySQL utils
ADD ./files/create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD ./files/mysql_setup.sh /mysql_setup.sh
RUN chmod 755 /*.sh

EXPOSE 80 3306
CMD ["/run.sh"]