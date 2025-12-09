-- ============================================
-- ETL脚本：ODS层 → DWD层
-- 数据清洗和转换
-- ============================================

USE education_dw;

-- 1. 清洗学员数据到DWD层
TRUNCATE TABLE dwd_student_detail;

INSERT INTO dwd_student_detail
SELECT 
    student_id,
    student_name,
    -- 手机号脱敏
    CONCAT(LEFT(phone, 3), '****', RIGHT(phone, 4)) AS phone_masked,
    -- 邮箱脱敏
    CASE 
        WHEN email LIKE '%@%' THEN 
            CONCAT(LEFT(SUBSTRING_INDEX(email, '@', 1), 1), 
                   '***', 
                   RIGHT(SUBSTRING_INDEX(email, '@', 1), 1),
                   '@',
                   SUBSTRING_INDEX(email, '@', -1))
        ELSE email
    END AS email_masked,
    -- 性别描述
    CASE gender 
        WHEN 1 THEN '男' 
        WHEN 2 THEN '女' 
        ELSE '未知' 
    END AS gender_desc,
    age,
    -- 年龄段
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age >= 46 THEN '46+'
        ELSE '未知'
    END AS age_group,
    province,
    city,
    district,
    NULL AS region_id,  -- 可以后续关联dim_region表
    register_time,
    DATE(register_time) AS register_date,
    vip_level,
    -- VIP等级描述
    CASE vip_level
        WHEN 0 THEN '普通'
        WHEN 1 THEN '银卡'
        WHEN 2 THEN '金卡'
        WHEN 3 THEN '钻石'
        ELSE '未知'
    END AS vip_level_desc,
    status,
    -- 状态描述
    CASE status
        WHEN 0 THEN '禁用'
        WHEN 1 THEN '正常'
        ELSE '未知'
    END AS status_desc,
    create_time,
    update_time
FROM ods_students;

-- 2. 清洗订单数据到DWD层
TRUNCATE TABLE dwd_order_detail;

INSERT INTO dwd_order_detail
SELECT 
    order_id,
    order_no,
    student_id,
    course_id,
    order_amount,
    discount_amount,
    paid_amount,
    -- 优惠率
    CASE 
        WHEN order_amount > 0 THEN ROUND((discount_amount / order_amount) * 100, 2)
        ELSE 0.00
    END AS discount_rate,
    payment_method,
    -- 支付方式描述
    CASE payment_method
        WHEN 1 THEN '微信支付'
        WHEN 2 THEN '支付宝'
        WHEN 3 THEN '银行卡'
        ELSE '未知'
    END AS payment_method_desc,
    order_status,
    -- 订单状态描述
    CASE order_status
        WHEN 0 THEN '待支付'
        WHEN 1 THEN '已支付'
        WHEN 2 THEN '已取消'
        WHEN 3 THEN '已退款'
        ELSE '未知'
    END AS order_status_desc,
    order_time,
    DATE(order_time) AS order_date,
    pay_time,
    DATE(pay_time) AS pay_date,
    cancel_time,
    -- 是否已支付
    CASE WHEN order_status = 1 THEN 1 ELSE 0 END AS is_paid,
    create_time,
    update_time
FROM ods_orders;

-- 3. 清洗学习记录数据到DWD层
TRUNCATE TABLE dwd_learning_detail;

INSERT INTO dwd_learning_detail
SELECT 
    record_id,
    student_id,
    course_id,
    lesson_id,
    lesson_name,
    learning_duration,
    -- 学习时长（小时）
    ROUND(learning_duration / 60.0, 2) AS learning_duration_hour,
    progress,
    -- 进度等级
    CASE 
        WHEN progress = 0 THEN '未开始'
        WHEN progress > 0 AND progress < 100 THEN '进行中'
        WHEN progress >= 100 THEN '已完成'
        ELSE '未知'
    END AS progress_level,
    is_completed,
    -- 完成状态描述
    CASE is_completed
        WHEN 0 THEN '未完成'
        WHEN 1 THEN '已完成'
        ELSE '未知'
    END AS is_completed_desc,
    learning_time,
    DATE(learning_time) AS learning_date,
    create_time,
    update_time
FROM ods_learning_records;

-- 统计清洗结果
SELECT 'dwd_student_detail' AS table_name, COUNT(*) AS record_count FROM dwd_student_detail
UNION ALL
SELECT 'dwd_order_detail', COUNT(*) FROM dwd_order_detail
UNION ALL
SELECT 'dwd_learning_detail', COUNT(*) FROM dwd_learning_detail;



