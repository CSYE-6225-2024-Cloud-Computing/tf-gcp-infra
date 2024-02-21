#!/bin/bash
exec >> /var/log/logfile.log 2>&1
# Set your GCP-specific configurations
PROJECT_ID=${var.project}
REGION=${var.region}

# Set your app-specific values
POSTGRES_DB=${var.postgres_db}
POSTGRES_USER=${var.postgres_user}
POSTGRES_PASSWORD=${var.postgres_password}
POSTGRES_URI=${var.postgres_uri}
POSTGRES_PORT=${var.postgres_port}
SERVER_PORT=${var.server_port}
APP_USER=${var.app_user}
APP_PASSWORD=${var.app_password}
APP_GROUP=${var.app_group}
APP_DIR=${var.app_dir}
ENV_DIR=${var.env_dir}

# Change ENV owner and permissions
sudo touch $ENV_DIR
# sudo chown $APP_USER:$APP_GROUP $ENV_DIR
sudo chmod 660 $ENV_DIR

# Add ENV variables
sudo echo POSTGRES_DATABASE_URL=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_URI:$POSTGRES_PORT/$POSTGRES_DB >> $ENV_DIR

# Restart systemd service
sudo systemctl restart webapp.service