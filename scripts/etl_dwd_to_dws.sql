-- ============================================
-- ETL脚本：DWD层 → DWS层
-- 主题域轻度汇总
-- ============================================

USE education_dw;

-- 1. 学员主题汇总（按学员维度汇总）
TRUNCATE TABLE dws_student_summary;

INSERT INTO dws_student_summary
SELECT 
    s.student_id,
    s.student_name,
    s.province,
    s.city,
    s.age_group,
    s.vip_level_desc,
    -- 订单汇总
    COUNT(DISTINCT o.order_id) AS total_order_count,
    SUM(CASE WHEN o.is_paid = 1 THEN 1 ELSE 0 END) AS paid_order_count,
    SUM(o.order_amount) AS total_order_amount,
    SUM(CASE WHEN o.is_paid = 1 THEN o.paid_amount ELSE 0 END) AS total_paid_amount,
    ROUND(AVG(CASE WHEN o.is_paid = 1 THEN o.paid_amount END), 2) AS avg_order_amount,
    -- 课程汇总
    COUNT(DISTINCT o.course_id) AS purchased_course_count,
    -- 学习汇总
    COALESCE(SUM(l.learning_duration), 0) AS total_learning_duration,
    ROUND(COALESCE(SUM(l.learning_duration_hour), 0), 2) AS total_learning_hours,
    COUNT(DISTINCT l.learning_date) AS learning_days,
    COUNT(DISTINCT CASE WHEN l.is_completed = 1 THEN l.course_id END) AS completed_course_count,
    -- 时间字段
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    MAX(l.learning_date) AS last_learning_date,
    NOW() AS create_time,
    NOW() AS update_time
FROM dwd_student_detail s
LEFT JOIN dwd_order_detail o ON s.student_id = o.student_id
LEFT JOIN dwd_learning_detail l ON s.student_id = l.student_id
GROUP BY s.student_id, s.student_name, s.province, s.city, s.age_group, s.vip_level_desc;

-- 2. 订单主题汇总（按日期+地区+课程分类+支付方式汇总）
TRUNCATE TABLE dws_order_summary;

INSERT INTO dws_order_summary
SELECT 
    o.order_date AS dt,
    s.province,
    s.city,
    c.category_name,
    o.payment_method_desc,
    -- 订单汇总
    COUNT(*) AS order_count,
    SUM(o.is_paid) AS paid_order_count,
    SUM(CASE WHEN o.order_status = 2 THEN 1 ELSE 0 END) AS cancel_order_count,
    SUM(o.order_amount) AS total_gmv,
    SUM(CASE WHEN o.is_paid = 1 THEN o.paid_amount ELSE 0 END) AS paid_gmv,
    SUM(o.discount_amount) AS total_discount,
    ROUND(AVG(o.order_amount), 2) AS avg_order_amount,
    ROUND(AVG(CASE WHEN o.is_paid = 1 THEN o.paid_amount END), 2) AS avg_paid_amount,
    -- 学员汇总
    COUNT(DISTINCT o.student_id) AS unique_student_count
FROM dwd_order_detail o
LEFT JOIN dwd_student_detail s ON o.student_id = s.student_id
LEFT JOIN ods_courses c ON o.course_id = c.course_id
WHERE o.order_date IS NOT NULL
GROUP BY o.order_date, s.province, s.city, c.category_name, o.payment_method_desc;

-- 3. 课程主题汇总（按课程维度汇总）
TRUNCATE TABLE dws_course_summary;

INSERT INTO dws_course_summary
SELECT 
    c.course_id,
    c.course_name,
    c.category_name,
    c.teacher_name,
    c.price,
    -- 销售汇总
    COUNT(DISTINCT o.order_id) AS total_order_count,
    SUM(CASE WHEN o.is_paid = 1 THEN 1 ELSE 0 END) AS paid_order_count,
    SUM(CASE WHEN o.is_paid = 1 THEN o.paid_amount ELSE 0 END) AS total_revenue,
    ROUND(AVG(CASE WHEN o.is_paid = 1 THEN o.paid_amount END), 2) AS avg_sale_price,
    -- 学员汇总
    COUNT(DISTINCT o.student_id) AS student_count,
    -- 学习汇总
    COUNT(l.record_id) AS total_learning_count,
    COALESCE(SUM(l.learning_duration), 0) AS total_learning_duration,
    ROUND(COALESCE(SUM(l.learning_duration_hour), 0), 2) AS total_learning_hours,
    ROUND(AVG(l.learning_duration_hour), 2) AS avg_learning_duration,
    SUM(CASE WHEN l.is_completed = 1 THEN 1 ELSE 0 END) AS completed_count,
    ROUND(AVG(l.progress), 2) AS avg_progress,
    -- 时间字段
    MIN(o.order_date) AS first_sale_date,
    MAX(o.order_date) AS last_sale_date,
    NOW() AS create_time,
    NOW() AS update_time
FROM ods_courses c
LEFT JOIN dwd_order_detail o ON c.course_id = o.course_id
LEFT JOIN dwd_learning_detail l ON c.course_id = l.course_id
WHERE c.status = 1
GROUP BY c.course_id, c.course_name, c.category_name, c.teacher_name, c.price;

-- 4. 学习行为主题汇总（按日期+学员+课程汇总）
TRUNCATE TABLE dws_learning_summary;

INSERT INTO dws_learning_summary
SELECT 
    l.learning_date AS dt,
    l.student_id,
    l.course_id,
    -- 学习汇总
    COUNT(*) AS learning_count,
    SUM(l.learning_duration) AS total_duration,
    ROUND(SUM(l.learning_duration_hour), 2) AS total_duration_hour,
    SUM(CASE WHEN l.is_completed = 1 THEN 1 ELSE 0 END) AS completed_lessons,
    MAX(l.progress) AS max_progress,
    ROUND(AVG(l.progress), 2) AS avg_progress,
    MAX(l.is_completed) AS is_completed
FROM dwd_learning_detail l
WHERE l.learning_date IS NOT NULL
GROUP BY l.learning_date, l.student_id, l.course_id;

-- 5. 地区主题汇总（按日期+地区汇总）
TRUNCATE TABLE dws_region_summary;

INSERT INTO dws_region_summary
SELECT 
    COALESCE(o.order_date, l.learning_date, s.register_date) AS dt,
    s.province,
    s.city,
    -- 学员汇总
    COUNT(DISTINCT CASE WHEN s.register_date = COALESCE(o.order_date, l.learning_date, s.register_date) THEN s.student_id END) AS new_student_count,
    COUNT(DISTINCT s.student_id) AS total_student_count,
    COUNT(DISTINCT CASE WHEN l.learning_date = COALESCE(o.order_date, l.learning_date, s.register_date) THEN s.student_id END) AS active_student_count,
    -- 订单汇总
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(CASE WHEN o.is_paid = 1 THEN 1 ELSE 0 END) AS paid_order_count,
    SUM(o.order_amount) AS total_gmv,
    SUM(CASE WHEN o.is_paid = 1 THEN o.paid_amount ELSE 0 END) AS paid_gmv,
    -- 学习汇总
    COUNT(DISTINCT CASE WHEN l.learning_date = COALESCE(o.order_date, l.learning_date, s.register_date) THEN l.student_id END) AS learning_student_count,
    COALESCE(SUM(l.learning_duration), 0) AS total_learning_duration
FROM dwd_student_detail s
LEFT JOIN dwd_order_detail o ON s.student_id = o.student_id AND o.order_date IS NOT NULL
LEFT JOIN dwd_learning_detail l ON s.student_id = l.student_id AND l.learning_date IS NOT NULL
WHERE s.province IS NOT NULL AND s.city IS NOT NULL
GROUP BY COALESCE(o.order_date, l.learning_date, s.register_date), s.province, s.city;

-- 统计汇总结果
SELECT 'dws_student_summary' AS table_name, COUNT(*) AS record_count FROM dws_student_summary
UNION ALL
SELECT 'dws_order_summary', COUNT(*) FROM dws_order_summary
UNION ALL
SELECT 'dws_course_summary', COUNT(*) FROM dws_course_summary
UNION ALL
SELECT 'dws_learning_summary', COUNT(*) FROM dws_learning_summary
UNION ALL
SELECT 'dws_region_summary', COUNT(*) FROM dws_region_summary;



