#!/bin/bash
exec >> /tmp/logfile.log 2>&1

# Set your app-specific values
DB_USERNAME=${google_sql_user.cloudsql_user[count.index].name}
DB_PASSWORD=${random_password.password.result}
DB_HOST=${google_sql_database_instance.cloudsql_instance[count.index].private_ip_address}
DB_NAME=${google_sql_database.cloudsql_database[count.index].name}
POSTGRES_PORT=${var.postgres_port}
APP_USER=${var.app_user}
APP_GROUP=${var.app_group}
ENV_DIR="/home/csye6225/webapp/app/.env"

# Change ENV owner and permissions
sudo touch $ENV_DIR
sudo chown $APP_USER:$APP_GROUP $ENV_DIR
sudo chmod 660 $ENV_DIR

# Add ENV variables
sudo echo POSTGRES_DATABASE_URL=postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$POSTGRES_PORT/$DB_NAME >> $ENV_DIR
sleep 5
# Restart systemd service
sudo systemctl restart webapp.service
