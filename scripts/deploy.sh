#!/bin/bash
# 在线教育平台数仓 - 一键部署脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 数据库配置
MYSQL_CONTAINER="mysql-db"
DB_USER="root"
DB_PASS="aCqFnbtJEuaoFVjmZctE6g=="
DB_NAME="education_dw"

# MySQL命令（通过Docker容器执行）
MYSQL_CMD="docker exec $MYSQL_CONTAINER mysql -u$DB_USER -p'$DB_PASS'"

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}在线教育平台数仓 - 一键部署${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查MySQL连接
echo -e "${YELLOW}[1/8] 检查MySQL连接...${NC}"
if ! docker exec "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}错误：无法连接到MySQL数据库容器${NC}"
    echo -e "${YELLOW}请确保MySQL容器正在运行: docker ps | grep mysql${NC}"
    exit 1
fi
echo -e "${GREEN}✓ MySQL连接成功${NC}"

# 创建数据库
echo -e "${YELLOW}[2/8] 创建数据库...${NC}"
docker exec "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
echo -e "${GREEN}✓ 数据库创建成功${NC}"

# 创建ODS层表
echo -e "${YELLOW}[3/8] 创建ODS层表...${NC}"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/ods/01_create_ods_tables.sql"
echo -e "${GREEN}✓ ODS层表创建成功${NC}"

# 创建DIM层表并初始化数据
echo -e "${YELLOW}[4/8] 创建DIM层表并初始化数据...${NC}"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/dim/03_create_dim_tables.sql"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCRIPT_DIR/init_dim_data.sql"
echo -e "${GREEN}✓ DIM层表创建和数据初始化成功${NC}"

# 创建DWD层表
echo -e "${YELLOW}[5/8] 创建DWD层表...${NC}"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/dwd/02_create_dwd_tables.sql"
echo -e "${GREEN}✓ DWD层表创建成功${NC}"

# 创建DWS层表
echo -e "${YELLOW}[6/8] 创建DWS层表...${NC}"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/dws/03_create_dws_tables.sql"
echo -e "${GREEN}✓ DWS层表创建成功${NC}"

# 创建ADS层表
echo -e "${YELLOW}[7/8] 创建ADS层表...${NC}"
docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_DIR/ads/04_create_ads_tables.sql"
echo -e "${GREEN}✓ ADS层表创建成功${NC}"

# 生成测试数据
echo -e "${YELLOW}[8/8] 生成测试数据（这可能需要几分钟）...${NC}"
if command -v python3 &> /dev/null; then
    # 检查是否安装了pymysql
    if ! python3 -c "import pymysql" 2>/dev/null; then
        echo -e "${YELLOW}正在安装pymysql...${NC}"
        pip3 install pymysql > /dev/null 2>&1 || pip install pymysql > /dev/null 2>&1
    fi
    python3 "$SCRIPT_DIR/generate_test_data.py"
    echo -e "${GREEN}✓ 测试数据生成成功${NC}"
    
    # 执行ETL
    echo -e "${YELLOW}执行数据清洗和转换...${NC}"
    docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCRIPT_DIR/etl_ods_to_dwd.sql"
    docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCRIPT_DIR/etl_dwd_to_dws.sql"
    docker exec -i "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SCRIPT_DIR/etl_dwd_to_ads.sql"
    echo -e "${GREEN}✓ 数据清洗和转换完成${NC}"
else
    echo -e "${RED}警告：未找到python3，跳过测试数据生成${NC}"
    echo -e "${YELLOW}请手动运行: python3 $SCRIPT_DIR/generate_test_data.py${NC}"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "数据统计："
docker exec "$MYSQL_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SELECT 
    'ods_students' AS table_name, COUNT(*) AS record_count FROM ods_students
UNION ALL
SELECT 'ods_courses', COUNT(*) FROM ods_courses
UNION ALL
SELECT 'ods_orders', COUNT(*) FROM ods_orders
UNION ALL
SELECT 'ods_learning_records', COUNT(*) FROM ods_learning_records
UNION ALL
SELECT 'dwd_student_detail', COUNT(*) FROM dwd_student_detail
UNION ALL
SELECT 'dwd_order_detail', COUNT(*) FROM dwd_order_detail
UNION ALL
SELECT 'dwd_learning_detail', COUNT(*) FROM dwd_learning_detail
UNION ALL
SELECT 'dws_student_summary', COUNT(*) FROM dws_student_summary
UNION ALL
SELECT 'dws_order_summary', COUNT(*) FROM dws_order_summary
UNION ALL
SELECT 'dws_course_summary', COUNT(*) FROM dws_course_summary
UNION ALL
SELECT 'dws_learning_summary', COUNT(*) FROM dws_learning_summary
UNION ALL
SELECT 'dws_region_summary', COUNT(*) FROM dws_region_summary
UNION ALL
SELECT 'ads_order_daily', COUNT(*) FROM ads_order_daily
UNION ALL
SELECT 'ads_student_profile', COUNT(*) FROM ads_student_profile
UNION ALL
SELECT 'ads_course_analysis', COUNT(*) FROM ads_course_analysis;
EOF

echo ""
echo -e "${GREEN}可以使用以下命令连接数据库查看数据：${NC}"
echo -e "docker exec -it $MYSQL_CONTAINER mysql -u$DB_USER -p'$DB_PASS' $DB_NAME"

