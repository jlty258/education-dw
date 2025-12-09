# 快速开始指南

## 📦 项目结构

```
education-dw/
├── README.md                    # 项目主文档
├── QUICK_START.md               # 快速开始指南（本文件）
├── sql/                         # SQL脚本目录
│   ├── ods/                     # ODS层建表脚本
│   │   └── 01_create_ods_tables.sql
│   ├── dwd/                     # DWD层建表脚本
│   │   └── 02_create_dwd_tables.sql
│   ├── dim/                     # DIM层建表脚本
│   │   └── 03_create_dim_tables.sql
│   ├── dws/                     # DWS层建表脚本
│   │   └── 03_create_dws_tables.sql
│   └── ads/                     # ADS层建表脚本
│       └── 04_create_ads_tables.sql
├── scripts/                     # 脚本目录
│   ├── deploy.sh                # 一键部署脚本
│   ├── generate_test_data.py    # 测试数据生成脚本
│   ├── init_dim_data.sql        # 维度数据初始化
│   ├── etl_ods_to_dwd.sql      # ODS→DWD ETL脚本
│   ├── etl_dwd_to_dws.sql      # DWD→DWS ETL脚本
│   └── etl_dwd_to_ads.sql      # DWS→ADS ETL脚本
└── docs/                        # 文档目录
    └── business_scenarios.md    # 业务场景SQL示例
```

## 🚀 一键部署

### 方式1：使用部署脚本（推荐）

```bash
cd /root/joyday/sqlwing/education-dw
./scripts/deploy.sh
```

### 方式2：手动部署

#### 步骤1：创建数据库

```bash
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' -e "CREATE DATABASE IF NOT EXISTS education_dw DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

#### 步骤2：创建表结构

```bash
# 创建ODS层表
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/ods/01_create_ods_tables.sql

# 创建DIM层表
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dim/03_create_dim_tables.sql

# 初始化维度数据
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/init_dim_data.sql

# 创建DWD层表
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dwd/02_create_dwd_tables.sql

# 创建DWS层表
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dws/03_create_dws_tables.sql

# 创建ADS层表
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/ads/04_create_ads_tables.sql
```

#### 步骤3：生成测试数据

```bash
# 安装依赖（如果未安装）
pip3 install pymysql

# 生成测试数据
python3 scripts/generate_test_data.py
```

#### 步骤4：执行ETL

```bash
# ODS → DWD
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_ods_to_dwd.sql

# DWD → DWS
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_dwd_to_dws.sql

# DWS → ADS
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_dwd_to_ads.sql
```

## 📊 验证部署

### 查看表数量

```bash
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw -e "SHOW TABLES;"
```

### 查看数据量

```bash
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw <<EOF
SELECT 
    'ods_students' AS table_name, COUNT(*) AS count FROM ods_students
UNION ALL SELECT 'ods_courses', COUNT(*) FROM ods_courses
UNION ALL SELECT 'ods_orders', COUNT(*) FROM ods_orders
UNION ALL SELECT 'ods_learning_records', COUNT(*) FROM ods_learning_records
UNION ALL SELECT 'dwd_student_detail', COUNT(*) FROM dwd_student_detail
UNION ALL SELECT 'dwd_order_detail', COUNT(*) FROM dwd_order_detail
UNION ALL SELECT 'dwd_learning_detail', COUNT(*) FROM dwd_learning_detail
UNION ALL SELECT 'ads_order_daily', COUNT(*) FROM ads_order_daily
UNION ALL SELECT 'ads_student_profile', COUNT(*) FROM ads_student_profile
UNION ALL SELECT 'ads_course_analysis', COUNT(*) FROM ads_course_analysis;
EOF
```

## 🔍 示例查询

### 查看最近7天订单GMV

```bash
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw <<EOF
SELECT 
    dt AS 日期,
    order_count AS 订单数,
    paid_gmv AS 已支付GMV,
    avg_order_amount AS 平均订单金额
FROM ads_order_daily
WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY dt DESC;
EOF
```

### 查看课程销售TOP10

```bash
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw <<EOF
SELECT 
    course_name AS 课程名称,
    category_name AS 分类,
    sales_count AS 销售数量,
    total_revenue AS 总营收,
    completion_rate AS 完课率
FROM ads_course_analysis
ORDER BY sales_count DESC
LIMIT 10;
EOF
```

更多业务场景SQL示例请查看 `docs/business_scenarios.md`

## 📝 数据规模

| 层级 | 表名 | 数据量 |
|------|------|--------|
| ODS | ods_students | 5,000 |
| ODS | ods_courses | 500 |
| ODS | ods_orders | **10,000** (最大表) |
| ODS | ods_learning_records | 8,000 |
| DWD | dwd_student_detail | 5,000 |
| DWD | dwd_order_detail | 10,000 |
| DWD | dwd_learning_detail | 8,000 |
| DIM | dim_date | 365 |
| DIM | dim_region | 100 |
| DIM | dim_course_category | 20 |
| DWS | dws_student_summary | 5,000 |
| DWS | dws_order_summary | ~2,000 |
| DWS | dws_course_summary | 500 |
| DWS | dws_learning_summary | ~3,000 |
| DWS | dws_region_summary | ~1,000 |
| ADS | ads_order_daily | ~365 |
| ADS | ads_student_profile | 5,000 |
| ADS | ads_course_analysis | 500 |

## ⚠️ 注意事项

1. **数据库密码**：默认使用容器中的root密码，如需修改请编辑脚本中的 `DB_PASS` 变量
2. **Python依赖**：需要安装 `pymysql` 库用于生成测试数据
3. **数据量**：最大表为订单表（10,000条），总数据量约40,000条
4. **执行时间**：数据生成可能需要几分钟时间，请耐心等待

## 🔧 故障排查

### 问题1：Python脚本执行失败

```bash
# 检查Python版本
python3 --version

# 安装pymysql
pip3 install pymysql
```

### 问题2：MySQL连接失败

```bash
# 检查MySQL容器是否运行
docker ps | grep mysql

# 检查密码是否正确
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' -e "SELECT 1"
```

### 问题3：表已存在错误

```bash
# 删除并重建数据库（谨慎操作）
docker exec mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' -e "DROP DATABASE IF EXISTS education_dw;"
# 然后重新执行部署脚本
```

## 📚 相关文档

- [README.md](README.md) - 项目主文档
- [docs/business_scenarios.md](docs/business_scenarios.md) - 业务场景SQL示例

