-- ============================================
-- ADS层建表SQL（应用数据服务层）
-- 在线教育平台数据仓库
-- ============================================

USE education_dw;

-- 1. 订单日汇总表
CREATE TABLE IF NOT EXISTS ads_order_daily (
    dt DATE PRIMARY KEY COMMENT '日期',
    order_count INT DEFAULT 0 COMMENT '订单数',
    paid_order_count INT DEFAULT 0 COMMENT '已支付订单数',
    total_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '总GMV（订单金额）',
    paid_gmv DECIMAL(15,2) DEFAULT 0.00 COMMENT '已支付GMV（实付金额）',
    total_discount DECIMAL(15,2) DEFAULT 0.00 COMMENT '总优惠金额',
    avg_order_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均订单金额',
    avg_paid_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均实付金额',
    cancel_order_count INT DEFAULT 0 COMMENT '取消订单数',
    cancel_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT '取消率（%）',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_dt (dt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单日汇总表';

-- 2. 学员画像表
CREATE TABLE IF NOT EXISTS ads_student_profile (
    student_id BIGINT PRIMARY KEY COMMENT '学员ID',
    student_name VARCHAR(50) NOT NULL COMMENT '学员姓名',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    age_group VARCHAR(20) COMMENT '年龄段',
    vip_level_desc VARCHAR(20) COMMENT 'VIP等级',
    total_orders INT DEFAULT 0 COMMENT '总订单数',
    total_paid_orders INT DEFAULT 0 COMMENT '已支付订单数',
    total_consumption DECIMAL(15,2) DEFAULT 0.00 COMMENT '总消费金额',
    avg_order_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均订单金额',
    total_courses INT DEFAULT 0 COMMENT '购买课程数',
    total_learning_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    total_learning_hours DECIMAL(10,2) DEFAULT 0.00 COMMENT '总学习时长（小时）',
    completed_courses INT DEFAULT 0 COMMENT '完成课程数',
    completion_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT '完课率（%）',
    last_learning_time DATETIME COMMENT '最后学习时间',
    register_days INT DEFAULT 0 COMMENT '注册天数',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_province_city (province, city),
    INDEX idx_vip_level (vip_level_desc),
    INDEX idx_total_consumption (total_consumption)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学员画像表';

-- 3. 课程分析表
CREATE TABLE IF NOT EXISTS ads_course_analysis (
    course_id BIGINT PRIMARY KEY COMMENT '课程ID',
    course_name VARCHAR(200) NOT NULL COMMENT '课程名称',
    category_name VARCHAR(100) COMMENT '分类名称',
    teacher_name VARCHAR(50) COMMENT '讲师姓名',
    price DECIMAL(10,2) COMMENT '课程价格',
    sales_count INT DEFAULT 0 COMMENT '销售数量（订单数）',
    paid_sales_count INT DEFAULT 0 COMMENT '已支付销售数量',
    total_revenue DECIMAL(15,2) DEFAULT 0.00 COMMENT '总营收',
    avg_price DECIMAL(10,2) DEFAULT 0.00 COMMENT '平均售价',
    student_count INT DEFAULT 0 COMMENT '学员数',
    learning_count INT DEFAULT 0 COMMENT '学习记录数',
    total_learning_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    completed_count INT DEFAULT 0 COMMENT '完成学习数',
    completion_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT '完课率（%）',
    avg_rating DECIMAL(3,2) DEFAULT 0.00 COMMENT '平均评分',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_category (category_name),
    INDEX idx_sales_count (sales_count),
    INDEX idx_total_revenue (total_revenue),
    INDEX idx_rating (avg_rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程分析表';

-- 4. 学习行为日汇总表
CREATE TABLE IF NOT EXISTS ads_learning_daily (
    dt DATE COMMENT '日期',
    student_id BIGINT COMMENT '学员ID',
    course_id BIGINT COMMENT '课程ID',
    learning_count INT DEFAULT 0 COMMENT '学习次数',
    total_duration INT DEFAULT 0 COMMENT '总学习时长（分钟）',
    total_duration_hour DECIMAL(10,2) DEFAULT 0.00 COMMENT '总学习时长（小时）',
    completed_lessons INT DEFAULT 0 COMMENT '完成课时数',
    avg_progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '平均学习进度',
    PRIMARY KEY (dt, student_id, course_id),
    INDEX idx_dt (dt),
    INDEX idx_student_id (student_id),
    INDEX idx_course_id (course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学习行为日汇总表';



