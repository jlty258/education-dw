-- ============================================
-- DIM层建表SQL（维度表）
-- 在线教育平台数据仓库
-- ============================================

USE education_dw;

-- 1. 日期维度表（生成1年的日期数据）
CREATE TABLE IF NOT EXISTS dim_date (
    date_id DATE PRIMARY KEY COMMENT '日期ID（YYYY-MM-DD）',
    year INT NOT NULL COMMENT '年份',
    quarter INT NOT NULL COMMENT '季度：1-4',
    month INT NOT NULL COMMENT '月份：1-12',
    week INT NOT NULL COMMENT '周数：1-53',
    day INT NOT NULL COMMENT '日期：1-31',
    day_of_week INT NOT NULL COMMENT '星期：1-7（周一到周日）',
    day_name VARCHAR(10) NOT NULL COMMENT '星期名称',
    is_weekend TINYINT NOT NULL DEFAULT 0 COMMENT '是否周末：0-否，1-是',
    is_holiday TINYINT NOT NULL DEFAULT 0 COMMENT '是否节假日：0-否，1-是',
    holiday_name VARCHAR(50) COMMENT '节假日名称',
    INDEX idx_year_month (year, month),
    INDEX idx_quarter (quarter),
    INDEX idx_week (week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日期维度表';

-- 2. 地区维度表
CREATE TABLE IF NOT EXISTS dim_region (
    region_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '地区ID',
    province VARCHAR(50) NOT NULL COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    district VARCHAR(50) COMMENT '区县',
    region_level TINYINT NOT NULL COMMENT '地区级别：1-省，2-市，3-区',
    parent_region_id BIGINT COMMENT '父级地区ID',
    region_code VARCHAR(20) COMMENT '地区编码',
    INDEX idx_province_city (province, city),
    INDEX idx_parent (parent_region_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='地区维度表';

-- 3. 课程分类维度表
CREATE TABLE IF NOT EXISTS dim_course_category (
    category_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '分类ID',
    category_name VARCHAR(100) NOT NULL COMMENT '分类名称',
    parent_category_id INT COMMENT '父分类ID',
    category_level TINYINT DEFAULT 1 COMMENT '分类级别：1-一级，2-二级',
    sort_order INT DEFAULT 0 COMMENT '排序',
    status TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_parent (parent_category_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程分类维度表';

-- 4. 支付方式维度表
CREATE TABLE IF NOT EXISTS dim_payment_method (
    payment_method_id TINYINT PRIMARY KEY COMMENT '支付方式ID',
    payment_method_name VARCHAR(20) NOT NULL COMMENT '支付方式名称',
    payment_method_code VARCHAR(20) COMMENT '支付方式代码',
    status TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-启用'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付方式维度表';

-- 初始化支付方式维度数据
INSERT INTO dim_payment_method (payment_method_id, payment_method_name, payment_method_code, status) VALUES
(1, '微信支付', 'WECHAT', 1),
(2, '支付宝', 'ALIPAY', 1),
(3, '银行卡', 'BANK_CARD', 1)
ON DUPLICATE KEY UPDATE payment_method_name=VALUES(payment_method_name);



