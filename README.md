# 在线教育平台数据仓库（MySQL版）

> **小型数仓实战案例 | 贴近实际业务 | 最大表1万条数据**

## 📋 目录

1. [业务背景](#1-业务背景)
2. [数仓架构](#2-数仓架构)
3. [数据模型](#3-数据模型)
4. [快速开始](#4-快速开始)
5. [数据流转](#5-数据流转)
6. [业务场景示例](#6-业务场景示例)

---

## 1. 业务背景

### 业务场景
- **业务**：在线教育平台（类似腾讯课堂、网易云课堂）
- **核心业务**：课程销售、学员学习、订单管理
- **数据规模**：小型数仓，最大表1万条数据

### 业务域划分

| 数据域 | 说明 | 核心表 |
|--------|------|--------|
| **student** | 学员域 | 学员信息、学员画像 |
| **course** | 课程域 | 课程信息、课程分类 |
| **order** | 订单域 | 订单明细、支付记录 |
| **learning** | 学习域 | 学习记录、学习进度 |

### 业务需求

| 需求 | 说明 |
|------|------|
| 订单分析 | 日度GMV、订单数、客单价、课程销售排行 |
| 学员画像 | 学员地域分布、学习偏好、消费能力 |
| 课程分析 | 课程热度、完课率、课程评分 |
| 学习行为 | 学习时长、学习进度、活跃度分析 |

---

## 2. 数仓架构

### 分层设计

```
┌─────────────────────────────────────────┐
│          ADS层（应用数据服务层）          │
│  日度GMV汇总、学员画像、课程分析汇总      │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│          DWS层（数据服务层/数据汇总层）    │
│  主题域轻度汇总：学员/订单/课程/学习汇总   │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│          DWD层（明细数据层）              │
│  清洗后的订单明细、学员明细、学习明细      │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│          DIM层（维度表）                  │
│  日期维度、地区维度、课程分类维度          │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│          ODS层（原始数据层）              │
│  原始业务表：学员、课程、订单、学习记录    │
└─────────────────────────────────────────┘
```

### 数据量设计

| 层级 | 表名 | 数据量 | 说明 |
|------|------|--------|------|
| ODS | ods_students | 5,000 | 学员原始表 |
| ODS | ods_courses | 500 | 课程原始表 |
| ODS | ods_orders | **10,000** | 订单原始表（最大表） |
| ODS | ods_learning_records | 8,000 | 学习记录原始表 |
| DWD | dwd_order_detail | 10,000 | 订单明细表 |
| DWD | dwd_student_detail | 5,000 | 学员明细表 |
| DWD | dwd_learning_detail | 8,000 | 学习明细表 |
| DIM | dim_date | 365 | 日期维度（1年） |
| DIM | dim_region | 100 | 地区维度 |
| DIM | dim_course_category | 20 | 课程分类维度 |
| DWS | dws_student_summary | 5,000 | 学员主题汇总 |
| DWS | dws_order_summary | ~2,000 | 订单主题汇总 |
| DWS | dws_course_summary | 500 | 课程主题汇总 |
| DWS | dws_learning_summary | ~3,000 | 学习行为主题汇总 |
| DWS | dws_region_summary | ~1,000 | 地区主题汇总 |
| ADS | ads_order_daily | 365 | 订单日汇总（1年） |
| ADS | ads_student_profile | 5,000 | 学员画像表 |
| ADS | ads_course_analysis | 500 | 课程分析表 |

---

## 3. 数据模型

### 3.1 ODS层（原始数据层）

**业务表设计：**

- `ods_students` - 学员表
- `ods_courses` - 课程表
- `ods_orders` - 订单表
- `ods_learning_records` - 学习记录表

### 3.2 DWD层（明细数据层）

**清洗转换后的明细表：**

- `dwd_student_detail` - 学员明细（含脱敏、标准化）
- `dwd_order_detail` - 订单明细（含状态转换、金额计算）
- `dwd_learning_detail` - 学习明细（含时长计算、进度标准化）

### 3.3 DIM层（维度表）

**维度表：**

- `dim_date` - 日期维度（年、月、周、季度、节假日）
- `dim_region` - 地区维度（省、市、区）
- `dim_course_category` - 课程分类维度
- `dim_payment_method` - 支付方式维度

### 3.4 DWS层（数据服务层/数据汇总层）

**主题域轻度汇总表：**

- `dws_student_summary` - 学员主题汇总（按学员维度汇总订单、课程、学习数据）
- `dws_order_summary` - 订单主题汇总（按日期+地区+课程分类+支付方式汇总）
- `dws_course_summary` - 课程主题汇总（按课程维度汇总销售、学员、学习数据）
- `dws_learning_summary` - 学习行为主题汇总（按日期+学员+课程汇总）
- `dws_region_summary` - 地区主题汇总（按日期+地区汇总学员、订单、学习数据）

### 3.5 ADS层（应用数据服务层）

**应用汇总表：**

- `ads_order_daily` - 订单日汇总（GMV、订单数、客单价）
- `ads_student_profile` - 学员画像（地域、消费、学习偏好）
- `ads_course_analysis` - 课程分析（销售、完课率、评分）
- `ads_learning_daily` - 学习行为日汇总（学习时长、活跃度）

---

## 4. 快速开始

### 4.1 创建数据库

```bash
# 登录MySQL容器
docker exec -it mysql-db mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g=='

# 创建数仓数据库
CREATE DATABASE IF NOT EXISTS education_dw DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE education_dw;
```

### 4.2 执行建表脚本

按顺序执行SQL脚本：

```bash
# 1. 创建ODS层表
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/ods/01_create_ods_tables.sql

# 2. 创建DIM层表
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dim/03_create_dim_tables.sql

# 3. 创建DWD层表
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dwd/02_create_dwd_tables.sql

# 4. 创建DWS层表
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/dws/03_create_dws_tables.sql

# 5. 创建ADS层表
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < sql/ads/04_create_ads_tables.sql
```

### 4.3 生成测试数据

```bash
# 生成测试数据（最大表1万条）
python3 scripts/generate_test_data.py
```

### 4.4 数据清洗转换

```bash
# 执行数据清洗和转换
# ODS → DWD
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_ods_to_dwd.sql

# DWD → DWS
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_dwd_to_dws.sql

# DWS → ADS
mysql -u root -p'aCqFnbtJEuaoFVjmZctE6g==' education_dw < scripts/etl_dwd_to_ads.sql
```

---

## 5. 数据流转

```
业务系统 → ODS层（原始数据）
         ↓
     数据清洗
         ↓
      DWD层（明细数据）
         ↓
   关联维度表（DIM层）
         ↓
   主题域轻度汇总
         ↓
      DWS层（数据服务层）
         ↓
     应用数据汇总
         ↓
      ADS层（应用数据）
         ↓
    BI报表/数据分析
```

---

## 6. 业务场景示例

### 场景1：订单GMV分析

```sql
-- 查询最近7天的订单GMV
SELECT 
    dt,
    order_count,
    total_gmv,
    avg_order_amount,
    paid_gmv
FROM ads_order_daily
WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY dt DESC;
```

### 场景2：学员地域分布

```sql
-- 学员地域分布TOP10
SELECT 
    province,
    city,
    student_count,
    total_consumption,
    avg_consumption
FROM ads_student_profile
GROUP BY province, city
ORDER BY student_count DESC
LIMIT 10;
```

### 场景3：课程销售排行

```sql
-- 课程销售TOP10
SELECT 
    course_name,
    category_name,
    sales_count,
    total_revenue,
    avg_price
FROM ads_course_analysis
ORDER BY sales_count DESC
LIMIT 10;
```

---

## 📊 数据规模总结

- **总表数**：20张表
- **最大表数据量**：10,000条（订单表）
- **总数据量**：约50,000条记录
- **适合场景**：小型数仓、学习演示、POC验证

---

## 🔧 技术栈

- **数据库**：MySQL 8.0+
- **数据模型**：星型模型（Star Schema）
- **分层架构**：ODS → DWD → DIM → DWS → ADS（五层架构）
- **数据量**：小型（最大表1万条）

---

## 🔍 Datafold 特性复现

### 结合 data-diff 和 datasource_guard

本项目结合 `data-diff` 和 `datasource_guard` 两个项目，复现 **Datafold** 的核心特性。

**核心功能：**
- ✅ **Schema Registry** - 数据源契约管理（基于 datasource_guard）
- ✅ **数据质量监控** - ETL数据一致性检查（基于 data-diff）
- ✅ **CI/CD 集成** - 自动化验证流程（GitHub Actions）
- ✅ **数据差异分析** - 跨层数据对比和验证
- ✅ **数据源守护** - Schema 变更自动验证和断流

**使用方式：**

```bash
# 1. 安装依赖
pip install jsonschema
cd ../../data-diff && pip install -e .

# 2. 使用 Datafold-like Platform
cd ../../education-dw
python3 scripts/datafold_platform.py

# 3. Schema 管理
# 查看 Schema: cat schemas/students/v1.json
# 提交 Schema 变更会自动触发 CI/CD 验证
```

**详细文档：** 
- [Datafold 特性复现方案](docs/datafold_integration.md)
- [数据质量集成方案](docs/data_quality_integration.md)

---

## 📝 注意事项

1. 本数仓设计为**小型数仓**，适合学习、演示、POC场景
2. 数据量控制在1万条以内，便于快速验证和测试
3. 采用经典的分层架构，贴近企业级数仓设计
4. 所有表均使用InnoDB引擎，支持事务
5. 建议定期备份数据，避免数据丢失
6. 可选集成 data-diff 进行数据质量检查

