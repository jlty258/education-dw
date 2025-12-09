-- ============================================
-- DWD层建表SQL（明细数据层）
-- 在线教育平台数据仓库
-- ============================================

USE education_dw;

-- 1. 学员明细表（含脱敏和标准化）
CREATE TABLE IF NOT EXISTS dwd_student_detail (
    student_id BIGINT PRIMARY KEY COMMENT '学员ID',
    student_name VARCHAR(50) NOT NULL COMMENT '学员姓名',
    phone_masked VARCHAR(20) COMMENT '手机号（脱敏）',
    email_masked VARCHAR(100) COMMENT '邮箱（脱敏）',
    gender_desc VARCHAR(10) COMMENT '性别描述：男/女',
    age INT COMMENT '年龄',
    age_group VARCHAR(20) COMMENT '年龄段：18-25, 26-35, 36-45, 46+',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    district VARCHAR(50) COMMENT '区县',
    region_id BIGINT COMMENT '地区ID',
    register_time DATETIME COMMENT '注册时间',
    register_date DATE COMMENT '注册日期',
    vip_level TINYINT DEFAULT 0 COMMENT 'VIP等级',
    vip_level_desc VARCHAR(20) COMMENT 'VIP等级描述',
    status TINYINT DEFAULT 1 COMMENT '状态',
    status_desc VARCHAR(10) COMMENT '状态描述',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_register_date (register_date),
    INDEX idx_province_city (province, city),
    INDEX idx_vip_level (vip_level),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学员明细表';

-- 2. 订单明细表（含状态转换和金额计算）
CREATE TABLE IF NOT EXISTS dwd_order_detail (
    order_id BIGINT PRIMARY KEY COMMENT '订单ID',
    order_no VARCHAR(50) NOT NULL UNIQUE COMMENT '订单号',
    student_id BIGINT NOT NULL COMMENT '学员ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    order_amount DECIMAL(10,2) NOT NULL COMMENT '订单金额',
    discount_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '优惠金额',
    paid_amount DECIMAL(10,2) NOT NULL COMMENT '实付金额',
    discount_rate DECIMAL(5,2) COMMENT '优惠率（%）',
    payment_method TINYINT COMMENT '支付方式ID',
    payment_method_desc VARCHAR(20) COMMENT '支付方式描述',
    order_status TINYINT DEFAULT 0 COMMENT '订单状态',
    order_status_desc VARCHAR(20) COMMENT '订单状态描述',
    order_time DATETIME COMMENT '下单时间',
    order_date DATE COMMENT '下单日期',
    pay_time DATETIME COMMENT '支付时间',
    pay_date DATE COMMENT '支付日期',
    cancel_time DATETIME COMMENT '取消时间',
    is_paid TINYINT DEFAULT 0 COMMENT '是否已支付：0-否，1-是',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_student_id (student_id),
    INDEX idx_course_id (course_id),
    INDEX idx_order_date (order_date),
    INDEX idx_pay_date (pay_date),
    INDEX idx_order_status (order_status),
    INDEX idx_is_paid (is_paid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单明细表';

-- 3. 学习明细表（含时长计算和进度标准化）
CREATE TABLE IF NOT EXISTS dwd_learning_detail (
    record_id BIGINT PRIMARY KEY COMMENT '记录ID',
    student_id BIGINT NOT NULL COMMENT '学员ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    lesson_id BIGINT COMMENT '课时ID',
    lesson_name VARCHAR(200) COMMENT '课时名称',
    learning_duration INT DEFAULT 0 COMMENT '学习时长（分钟）',
    learning_duration_hour DECIMAL(10,2) COMMENT '学习时长（小时）',
    progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '学习进度（0-100%）',
    progress_level VARCHAR(20) COMMENT '进度等级：未开始/进行中/已完成',
    is_completed TINYINT DEFAULT 0 COMMENT '是否完成',
    is_completed_desc VARCHAR(10) COMMENT '完成状态描述',
    learning_time DATETIME COMMENT '学习时间',
    learning_date DATE COMMENT '学习日期',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_student_course (student_id, course_id),
    INDEX idx_learning_date (learning_date),
    INDEX idx_is_completed (is_completed),
    INDEX idx_progress (progress)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学习明细表';



