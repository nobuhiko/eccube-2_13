#!/bin/sh

######################################################################
#
# EC-CUBE のインストールを行う shell スクリプト
#
#
# #処理内容
# 1. パーミッション変更
# 2. html/install/sql 配下の SQL を実行
# 3. 管理者権限をアップデート
# 4. data/config/config.php を生成
#
# 使い方
# Configurationの内容を自分の環境に併せて修正
# PostgreSQLの場合は、DBユーザーを予め作成しておいて
# # ./ec_cube_install.sh pgsql
# MySQLはMYSQLのRoot以外のユーザーで実行する場合は、128行目をコメントアウトして
# # ./ec_cube_install.sh mysql
#
#
# 開発コミュニティの関連スレッド
# http://xoops.ec-cube.net/modules/newbb/viewtopic.php?topic_id=4918&forum=14&post_id=23090#forumpost23090
#
#######################################################################

#######################################################################
# Configuration
#-- Shop Configuration
CONFIG_PHP="data/config/config.php"
ADMIN_MAIL=${ADMIN_MAIL:-"admin@example.com"}
SHOP_NAME=${SHOP_NAME:-"EC-CUBE SHOP"}
HTTP_URL=${HTTP_URL:-"https://polar-citadel-45053.herokuapp.com/"}
HTTPS_URL=${HTTPS_URL:-"https://polar-citadel-45053.herokuapp.com/"}
ROOT_URLPATH=${ROOT_URLPATH:-"/"}
DOMAIN_NAME=${DOMAIN_NAME:-""}
ADMIN_DIR=${ADMIN_DIR:-"admin/"}

DBSERVER=${DBSERVER-"ec2-174-129-192-200.compute-1.amazonaws.com"}
DBNAME=${DBNAME:-"dfe4mql1b47u0g"}
DBUSER=${DBUSER:-"tobdiairqjrhte"}
DBPASS=${DBPASS:-"1aee62b8f0884cebd14fba8f123bf7ab7caa65e8effe6a6ffe2b2b9b90349de1"}

ADMINPASS="f6b126507a5d00dbdbb0f326fe855ddf84facd57c5603ffdf7e08fbb46bd633c"
AUTH_MAGIC="droucliuijeanamiundpnoufrouphudrastiokec"

DBTYPE=$1;

if [ $DBTYPE = "heroku" ]; then
  echo "Heroku file copy..."
cp -rv "./tests/config.php" "./${CONFIG_PHP}"
fi

case "${DBTYPE}" in
"heroku" )
    #-- DB Seting Postgres
    PSQL="psql -h ${DBSERVER}"
    export PGPASSWORD=${DBPASS}
    PGUSER=postgres
    DROPDB="heroku pg:reset DATABASE"
    DBPORT=5432
;;
"appveyor" )
    #-- DB Seting Postgres
    PSQL=psql
    PGUSER=postgres
    DROPDB=dropdb
    CREATEDB=createdb
    DBPORT=5432
;;
"pgsql" )
    #-- DB Seting Postgres
    PSQL=psql
    PGUSER=postgres
    DROPDB=dropdb
    CREATEDB=createdb
    DBPORT=5432
    DB=$1;
;;
"mysql" )
    #-- DB Seting MySQL
    MYSQL=mysql
    ROOTUSER=root
    ROOTPASS=$DBPASS
    DBSERVER="127.0.0.1"
    DBPORT=3306
    DB=mysqli;
;;
* ) echo "ERROR:: argument is invaid"
exit
;;
esac


#######################################################################
# Functions

adjust_directory_permissions()
{
    chmod -R go+w "./html"
    chmod go+w "./data"
    chmod -R go+w "./data/Smarty"
    chmod -R go+w "./data/cache"
    chmod -R go+w "./data/class"
    chmod -R go+w "./data/class_extends"
    chmod go+w "./data/config"
    chmod -R go+w "./data/download"
    chmod -R go+w "./data/downloads"
    chmod go+w "./data/fonts"
    chmod go+w "./data/include"
    chmod go+w "./data/logs"
    chmod -R go+w "./data/module"
    chmod go+w "./data/smarty_extends"
    chmod go+w "./data/upload"
    chmod go+w "./data/upload/csv"
}

create_sequence_tables()
{
    SEQUENCES="
dtb_best_products_best_id_seq
dtb_bloc_bloc_id_seq
dtb_category_category_id_seq
dtb_class_class_id_seq
dtb_classcategory_classcategory_id_seq
dtb_csv_no_seq
dtb_csv_sql_sql_id_seq
dtb_customer_customer_id_seq
dtb_deliv_deliv_id_seq
dtb_holiday_holiday_id_seq
dtb_kiyaku_kiyaku_id_seq
dtb_mail_history_send_id_seq
dtb_maker_maker_id_seq
dtb_member_member_id_seq
dtb_module_update_logs_log_id_seq
dtb_news_news_id_seq
dtb_order_order_id_seq
dtb_order_detail_order_detail_id_seq
dtb_other_deliv_other_deliv_id_seq
dtb_pagelayout_page_id_seq
dtb_payment_payment_id_seq
dtb_products_class_product_class_id_seq
dtb_products_product_id_seq
dtb_review_review_id_seq
dtb_send_history_send_id_seq
dtb_mailmaga_template_template_id_seq
dtb_plugin_plugin_id_seq
dtb_plugin_hookpoint_plugin_hookpoint_id_seq
dtb_api_config_api_config_id_seq
dtb_api_account_api_account_id_seq
dtb_tax_rule_tax_rule_id_seq
"

    comb_sql="";
    for S in $SEQUENCES; do
        case ${DBTYPE} in
            heroku)
                sql=$(echo "CREATE SEQUENCE ${S} START 10000;")
            ;;
            appveyor)
                sql=$(echo "CREATE SEQUENCE ${S} START 10000;")
            ;;
            pgsql)
                sql=$(echo "CREATE SEQUENCE ${S} START 10000;")
            ;;
            mysql)
                sql=$(echo "CREATE TABLE ${S} (
                        sequence int(11) NOT NULL AUTO_INCREMENT,
                        PRIMARY KEY (sequence)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
                    LOCK TABLES ${S} WRITE;
                    INSERT INTO ${S} VALUES (10000);
                    UNLOCK TABLES;")
            ;;
        esac

        comb_sql=${comb_sql}${sql}
    done;

    case ${DBTYPE} in
        heroku)
            echo ${comb_sql} | ${PSQL} -U ${DBUSER} ${DBNAME}
        ;;
        appveyor)
            echo ${comb_sql} | ${PSQL} -U ${DBUSER} ${DBNAME}
        ;;
        pgsql)
            echo ${comb_sql} | sudo -u ${PGUSER} ${PSQL} -U ${DBUSER} ${DBNAME}
        ;;
        mysql)
            echo ${comb_sql} | ${MYSQL} -u ${DBUSER} ${PASSOPT} ${DBNAME}
        ;;
    esac
}

get_optional_sql()
{
    echo "INSERT INTO dtb_member (member_id, login_id, password, salt, work, del_flg, authority, creator_id, rank, update_date) VALUES (2, 'admin', '${ADMINPASS}', '${AUTH_MAGIC}', '1', '0', '0', '0', '1', current_timestamp);"
    echo "INSERT INTO dtb_baseinfo (id, shop_name, email01, email02, email03, email04, top_tpl, product_tpl, detail_tpl, mypage_tpl, update_date) VALUES (1, '${SHOP_NAME}', '${ADMIN_MAIL}', '${ADMIN_MAIL}', '${ADMIN_MAIL}', '${ADMIN_MAIL}', 'default1', 'default1', 'default1', 'default1', current_timestamp);"
}

create_config_php()
{
    cat > "./${CONFIG_PHP}" <<__EOF__
<?php
define('ECCUBE_INSTALL', 'ON');
define('HTTP_URL', '${HTTP_URL}');
define('HTTPS_URL', '${HTTPS_URL}');
define('ROOT_URLPATH', '${ROOT_URLPATH}');
define('DOMAIN_NAME', '${DOMAIN_NAME}');
define('DB_TYPE', '${DB}');
define('DB_USER', '${DBUSER}');
define('DB_PASSWORD', '${CONFIGPASS:-$DBPASS}');
define('DB_SERVER', '${DBSERVER}');
define('DB_NAME', '${DBNAME}');
define('DB_PORT', '${DBPORT}');
define('ADMIN_DIR', '${ADMIN_DIR}');
define('ADMIN_FORCE_SSL', FALSE);
define('ADMIN_ALLOW_HOSTS', 'a:0:{}');
define('AUTH_MAGIC', '${AUTH_MAGIC}');
define('PASSWORD_HASH_ALGOS', 'sha256');
define('MAIL_BACKEND', 'mail');
define('SMTP_HOST', '');
define('SMTP_PORT', '');
define('SMTP_USER', '');
define('SMTP_PASSWORD', '');

__EOF__
}


#######################################################################
# Install

#-- Update Permissions
echo "update permissions..."
adjust_directory_permissions

#-- Setup Database
SQL_DIR="./html/install/sql"

case "${DBTYPE}" in
"heroku" )
    # PostgreSQL
    echo "dropdb..."
    ${DROPDB} ${DBNAME}
    echo "create table..."
    ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/create_table_pgsql.sql ${DBNAME}
    echo "insert data..."
    ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/insert_data.sql ${DBNAME}
    echo "create sequence table..."
    create_sequence_tables
    echo "execute optional SQL..."
    get_optional_sql | ${PSQL} -h ${DBSERVER} -U ${DBUSER} ${DBNAME}
	DBTYPE="pgsql"
;;
"appveyor" )
    # PostgreSQL
    echo "dropdb..."
    ${DROPDB} ${DBNAME}
    echo "createdb..."
    ${CREATEDB} -U ${DBUSER} ${DBNAME} 
    echo "create table..."
    ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/create_table_pgsql.sql ${DBNAME}
    echo "insert data..."
    ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/insert_data.sql ${DBNAME}
    echo "create sequence table..."
    create_sequence_tables
    echo "execute optional SQL..."
    get_optional_sql | ${PSQL} -h ${DBSERVER} -U ${DBUSER} ${DBNAME}
	DBTYPE="pgsql"
;;
"pgsql" )
    # PostgreSQL
    echo "dropdb..."
    sudo -u ${PGUSER} ${DROPDB} ${DBNAME}
    echo "createdb..."
    sudo -u ${PGUSER} ${CREATEDB} -U ${DBUSER} ${DBNAME}
    echo "create table..."
    sudo -u ${PGUSER} ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/create_table_pgsql.sql ${DBNAME}
    echo "insert data..."
    sudo -u ${PGUSER} ${PSQL} -U ${DBUSER} -f ${SQL_DIR}/insert_data.sql ${DBNAME}
    echo "create sequence table..."
    create_sequence_tables
    echo "execute optional SQL..."
    get_optional_sql | sudo -u ${PGUSER} ${PSQL} -U ${DBUSER} ${DBNAME}
;;
"mysql" )
    DBPASS=`echo $DBPASS | tr -d " "`
    if [ -n ${DBPASS} ]; then
	PASSOPT="--password=$DBPASS"
	CONFIGPASS=$DBPASS
    fi
    # MySQL
    echo "dropdb..."
    ${MYSQL} -u ${ROOTUSER} ${PASSOPT} -e "drop database \`${DBNAME}\`"
    echo "createdb..."
    ${MYSQL} -u ${ROOTUSER} ${PASSOPT} -e "create database \`${DBNAME}\` DEFAULT COLLATE=utf8_general_ci;"
    #echo "grant user..."
    #${MYSQL} -u ${ROOTUSER} ${PASSOPT} -e "GRANT ALL ON \`${DBNAME}\`.* TO '${DBUSER}'@'%' IDENTIFIED BY '${DBPASS}'"
    echo "create table..."
    echo "SET SESSION storage_engine = InnoDB;" |
        cat - ${SQL_DIR}/create_table_mysqli.sql |
        ${MYSQL} -u ${DBUSER} ${PASSOPT} ${DBNAME}
    echo "insert data..."
    ${MYSQL} -u ${DBUSER} ${PASSOPT} ${DBNAME} < ${SQL_DIR}/insert_data.sql
    echo "create sequence table..."
    create_sequence_tables
    echo "execute optional SQL..."
    get_optional_sql | ${MYSQL} -u ${DBUSER} ${PASSOPT} ${DBNAME}
;;
esac

#-- Setup Initial Data

echo "copy images..."
cp -rv "./html/install/save_image" "./html/upload/"

echo "creating ${CONFIG_PHP}..."
create_config_php

echo "Finished Successful!"
