-- ============================================
-- DWS层建表SQL（数据服务层/数据汇总层）
-- 在线教育平台数据仓库
-- 作用：主题域轻度汇总，为ADS层提供数据基础
-- ============================================

USE education_dw;

-- 1. 学员主题汇总表（按学员维度汇总）
CREATE TABLE IF NOT EXISTS dws_student_summary (
    student_id BIGINT PRIMARY KEY COMMENT '学员ID',
    student_name VARCHAR(50) COMMENT '学员姓名',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    age_group VARCHAR(20) COMMENT '年龄段',
    vip_level_desc VARCHAR(20) COMMENT 'VIP等级',
    -- 订单汇总
    total_order_count INT DEFAULT 0 COMMENT '总订单数',
    paid_order_count INT DEFAULT 0 COMMENT '已支付订单数',
    total_order_amount DECIMAL(15,2) DEFAULT 0.00 COMMENT '总订单金额',
    total_paid_amount DECIMAL(15,2) DEFAULT 0.00 COMMENT '总实付金额',
    avg_order_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均订单金额',
    -- 课程汇总
    purchased_course_count INT DEFAULT 0 COMMENT '购买课程数',
    -- 学习汇总
    total_learning_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    total_learning_hours DECIMAL(10,2) DEFAULT 0.00 COMMENT '总学习时长（小时）',
    learning_days INT DEFAULT 0 COMMENT '学习天数',
    completed_course_count INT DEFAULT 0 COMMENT '完成课程数',
    -- 时间字段
    first_order_date DATE COMMENT '首次下单日期',
    last_order_date DATE COMMENT '最后下单日期',
    last_learning_date DATE COMMENT '最后学习日期',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_province_city (province, city),
    INDEX idx_vip_level (vip_level_desc),
    INDEX idx_total_paid_amount (total_paid_amount)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学员主题汇总表';

-- 2. 订单主题汇总表（按日期+地区+课程分类汇总）
CREATE TABLE IF NOT EXISTS dws_order_summary (
    dt DATE COMMENT '日期',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    category_name VARCHAR(100) COMMENT '课程分类',
    payment_method_desc VARCHAR(20) COMMENT '支付方式',
    -- 订单汇总
    order_count INT DEFAULT 0 COMMENT '订单数',
    paid_order_count INT DEFAULT 0 COMMENT '已支付订单数',
    cancel_order_count INT DEFAULT 0 COMMENT '取消订单数',
    total_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '总GMV',
    paid_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '已支付GMV',
    total_discount DECIMAL(15,2) DEFAULT 0.00 COMMENT '总优惠金额',
    avg_order_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均订单金额',
    avg_paid_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均实付金额',
    -- 学员汇总
    unique_student_count INT DEFAULT 0 COMMENT '去重学员数',
    PRIMARY KEY (dt, province, city, category_name, payment_method_desc),
    INDEX idx_dt (dt),
    INDEX idx_province_city (province, city),
    INDEX idx_category (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主题汇总表';

-- 3. 课程主题汇总表（按课程维度汇总）
CREATE TABLE IF NOT EXISTS dws_course_summary (
    course_id BIGINT PRIMARY KEY COMMENT '课程ID',
    course_name VARCHAR(200) COMMENT '课程名称',
    category_name VARCHAR(100) COMMENT '课程分类',
    teacher_name VARCHAR(50) COMMENT '讲师姓名',
    price DECIMAL(10,2) COMMENT '课程价格',
    -- 销售汇总
    total_order_count INT DEFAULT 0 COMMENT '总订单数',
    paid_order_count INT DEFAULT 0 COMMENT '已支付订单数',
    total_revenue DECIMAL(15,2) DEFAULT 0.00 COMMENT '总营收',
    avg_sale_price DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均售价',
    -- 学员汇总
    student_count INT DEFAULT 0 COMMENT '学员数',
    -- 学习汇总
    total_learning_count INT DEFAULT 0 COMMENT '总学习次数',
    total_learning_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    total_learning_hours DECIMAL(10,2) DEFAULT 0.00 COMMENT '总学习时长（小时）',
    avg_learning_duration DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均学习时长（小时）',
    completed_count INT DEFAULT 0 COMMENT '完成学习数',
    avg_progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '平均学习进度',
    -- 时间字段
    first_sale_date DATE COMMENT '首次销售日期',
    last_sale_date DATE COMMENT '最后销售日期',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_category (category_name),
    INDEX idx_total_revenue (total_revenue),
    INDEX idx_student_count (student_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程主题汇总表';

-- 4. 学习行为主题汇总表（按日期+学员+课程汇总）
CREATE TABLE IF NOT EXISTS dws_learning_summary (
    dt DATE COMMENT '日期',
    student_id BIGINT COMMENT '学员ID',
    course_id BIGINT COMMENT '课程ID',
    -- 学习汇总
    learning_count INT DEFAULT 0 COMMENT '学习次数',
    total_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    total_duration_hour DECIMAL(10,2) DEFAULT 0.00 COMMENT '总学习时长（小时）',
    completed_lessons INT DEFAULT 0 COMMENT '完成课时数',
    max_progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '最大学习进度',
    avg_progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '平均学习进度',
    is_completed TINYINT DEFAULT 0 COMMENT '是否完成课程',
    PRIMARY KEY (dt, student_id, course_id),
    INDEX idx_dt (dt),
    INDEX idx_student_id (student_id),
    INDEX idx_course_id (course_id),
    INDEX idx_is_completed (is_completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学习行为主题汇总表';

-- 5. 地区主题汇总表（按日期+地区汇总）
CREATE TABLE IF NOT EXISTS dws_region_summary (
    dt DATE COMMENT '日期',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    -- 学员汇总
    new_student_count INT DEFAULT 0 COMMENT '新增学员数',
    total_student_count INT DEFAULT 0 COMMENT '累计学员数',
    active_student_count INT DEFAULT 0 COMMENT '活跃学员数',
    -- 订单汇总
    order_count INT DEFAULT 0 COMMENT '订单数',
    paid_order_count INT DEFAULT 0 COMMENT '已支付订单数',
    total_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '总GMV',
    paid_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '已支付GMV',
    -- 学习汇总
    learning_student_count INT DEFAULT 0 COMMENT '学习学员数',
    total_learning_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    PRIMARY KEY (dt, province, city),
    INDEX idx_dt (dt),
    INDEX idx_province_city (province, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='地区主题汇总表';



