-- ============================================
-- ODS层建表SQL（原始数据层）
-- 在线教育平台数据仓库
-- ============================================

USE education_dw;

-- 1. 学员原始表
CREATE TABLE IF NOT EXISTS ods_students (
    student_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '学员ID',
    student_name VARCHAR(50) NOT NULL COMMENT '学员姓名',
    phone VARCHAR(20) COMMENT '手机号',
    email VARCHAR(100) COMMENT '邮箱',
    gender TINYINT COMMENT '性别：1-男，2-女',
    age INT COMMENT '年龄',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    district VARCHAR(50) COMMENT '区县',
    register_time DATETIME COMMENT '注册时间',
    vip_level TINYINT DEFAULT 0 COMMENT 'VIP等级：0-普通，1-银卡，2-金卡，3-钻石',
    status TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_register_time (register_time),
    INDEX idx_province_city (province, city),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学员原始表';

-- 2. 课程原始表
CREATE TABLE IF NOT EXISTS ods_courses (
    course_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '课程ID',
    course_name VARCHAR(200) NOT NULL COMMENT '课程名称',
    category_id INT COMMENT '分类ID',
    category_name VARCHAR(100) COMMENT '分类名称',
    teacher_id BIGINT COMMENT '讲师ID',
    teacher_name VARCHAR(50) COMMENT '讲师姓名',
    price DECIMAL(10,2) NOT NULL COMMENT '课程价格',
    original_price DECIMAL(10,2) COMMENT '原价',
    course_type TINYINT COMMENT '课程类型：1-录播，2-直播，3-混合',
    difficulty_level TINYINT COMMENT '难度等级：1-初级，2-中级，3-高级',
    total_lessons INT DEFAULT 0 COMMENT '总课时数',
    total_duration INT DEFAULT 0 COMMENT '总时长（分钟）',
    student_count INT DEFAULT 0 COMMENT '学员数',
    rating DECIMAL(3,2) DEFAULT 0.00 COMMENT '评分（0-5分）',
    status TINYINT DEFAULT 1 COMMENT '状态：0-下架，1-上架',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='课程原始表';

-- 3. 订单原始表（最大表，1万条）
CREATE TABLE IF NOT EXISTS ods_orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单ID',
    order_no VARCHAR(50) NOT NULL UNIQUE COMMENT '订单号',
    student_id BIGINT NOT NULL COMMENT '学员ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    order_amount DECIMAL(10,2) NOT NULL COMMENT '订单金额',
    discount_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '优惠金额',
    paid_amount DECIMAL(10,2) NOT NULL COMMENT '实付金额',
    payment_method TINYINT COMMENT '支付方式：1-微信，2-支付宝，3-银行卡',
    order_status TINYINT DEFAULT 0 COMMENT '订单状态：0-待支付，1-已支付，2-已取消，3-已退款',
    order_time DATETIME COMMENT '下单时间',
    pay_time DATETIME COMMENT '支付时间',
    cancel_time DATETIME COMMENT '取消时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_student_id (student_id),
    INDEX idx_course_id (course_id),
    INDEX idx_order_time (order_time),
    INDEX idx_order_status (order_status),
    INDEX idx_order_no (order_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单原始表';

-- 4. 学习记录原始表
CREATE TABLE IF NOT EXISTS ods_learning_records (
    record_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '记录ID',
    student_id BIGINT NOT NULL COMMENT '学员ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    lesson_id BIGINT COMMENT '课时ID',
    lesson_name VARCHAR(200) COMMENT '课时名称',
    learning_duration INT DEFAULT 0 COMMENT '学习时长（分钟）',
    progress DECIMAL(5,2) DEFAULT 0.00 COMMENT '学习进度（0-100%）',
    is_completed TINYINT DEFAULT 0 COMMENT '是否完成：0-未完成，1-已完成',
    learning_time DATETIME COMMENT '学习时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_student_course (student_id, course_id),
    INDEX idx_learning_time (learning_time),
    INDEX idx_is_completed (is_completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学习记录原始表';



