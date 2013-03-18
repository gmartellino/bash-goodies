#!/bin/sh

###########################################################
# SYNC UP A STAGED WORDPRESS SITE WITH PRODUCTION CONTENT

# Author: Gary Martellino
# Company: Toi (http://toi.io)
# 
# script assumes only the theme is versioned or unique, there are
# two separate wordpress installs running: 1 in production, 1 for staging.
# This script can be run to copy production content to the staging WP install
#
# copies: production db to staging, changes siteurl & home wp_options
# copies: production uploads to staging /wp-content/uploads
# permissions: sets proper permissions over uploaded content
#
# note: does not copy over plugins
###########################################################

# Variables

DB_HOST="localhost"
DB_USER="db_user"
DB_PASS="db_password"
DB_NAME="db_production"
STAGING_DB="db_staging"
STAGING_URL="http://staging.yoursite.com"
STAGING_UPLOAD_PATH="/var/www/vhosts/staging.yoursite.com/www/wp-content/uploads"
PRODUCTION_UPLOAD_PATH="/var/www/html/wp-content/uploads"
APACHE_USER="apache"
APACHE_GROUP="apache"

# Copy uploaded content from production to staging

echo "Copying uploaded content from production to staging site."
yes "n" | cp -Rf $PRODUCTION_UPLOAD_PATH/* $STAGING_UPLOAD_PATH

# Sync staging database with production

echo "Copying production MySQL database"
mysqldump $DB_NAME -h$DB_HOST -u$DB_USER -p$DB_PASS > "./$DB_NAME.sql"

echo "Syncing DB"
mysql -u $DB_USER -p$DB_PASS $STAGING_DB < "./$DB_NAME.sql"

echo "Deleting dump file"
rm -rf ./$DB_NAME.sql

echo "Updating WordPress Options w/ Staging Parameters"
mysql -u $DB_USER -p$DB_PASS -e "UPDATE wp_options SET option_value = '$STAGING_URL' WHERE option_name = 'siteurl'" $STAGING_DB
mysql -u $DB_USER -p$DB_PASS -e "UPDATE wp_options SET option_value = '$STAGING_URL' WHERE option_name = 'home'" $STAGING_DB

# Update permissions

echo "Updating permissions."
chown -R $APACHE_USER:$APACHE_GROUP $PRODUCTION_UPLOAD_PATH

echo "Done."
exit 0