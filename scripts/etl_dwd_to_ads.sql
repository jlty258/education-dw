-- ============================================
-- ETL脚本：DWS层 → ADS层
-- 数据汇总和聚合（从DWS层汇总到ADS层）
-- ============================================

USE education_dw;

-- 1. 生成订单日汇总（从DWS层汇总）
TRUNCATE TABLE ads_order_daily;

INSERT INTO ads_order_daily
SELECT 
    dt,
    SUM(order_count) AS order_count,
    SUM(paid_order_count) AS paid_order_count,
    SUM(total_gmv) AS total_gmv,
    SUM(paid_gmv) AS paid_gmv,
    SUM(total_discount) AS total_discount,
    ROUND(SUM(total_gmv) / NULLIF(SUM(order_count), 0), 2) AS avg_order_amount,
    ROUND(SUM(paid_gmv) / NULLIF(SUM(paid_order_count), 0), 2) AS avg_paid_amount,
    SUM(cancel_order_count) AS cancel_order_count,
    ROUND(SUM(cancel_order_count) * 100.0 / NULLIF(SUM(order_count), 0), 2) AS cancel_rate,
    NOW() AS create_time,
    NOW() AS update_time
FROM dws_order_summary
GROUP BY dt
ORDER BY dt;

-- 2. 生成学员画像（从DWS层汇总）
TRUNCATE TABLE ads_student_profile;

INSERT INTO ads_student_profile
SELECT 
    student_id,
    student_name,
    province,
    city,
    age_group,
    vip_level_desc,
    -- 订单统计
    total_order_count AS total_orders,
    paid_order_count AS total_paid_orders,
    total_paid_amount AS total_consumption,
    avg_order_amount,
    -- 课程统计
    purchased_course_count AS total_courses,
    -- 学习统计
    total_learning_duration,
    total_learning_hours,
    completed_course_count AS completed_courses,
    -- 完课率
    CASE 
        WHEN purchased_course_count > 0 THEN
            ROUND(completed_course_count * 100.0 / purchased_course_count, 2)
        ELSE 0.00
    END AS completion_rate,
    NULL AS last_learning_time,  -- 可以从DWD层补充
    DATEDIFF(CURDATE(), COALESCE(first_order_date, CURDATE())) AS register_days,
    NOW() AS create_time,
    NOW() AS update_time
FROM dws_student_summary;

-- 3. 生成课程分析（从DWS层汇总）
TRUNCATE TABLE ads_course_analysis;

INSERT INTO ads_course_analysis
SELECT 
    cs.course_id,
    cs.course_name,
    cs.category_name,
    cs.teacher_name,
    cs.price,
    -- 销售统计
    cs.total_order_count AS sales_count,
    cs.paid_order_count AS paid_sales_count,
    cs.total_revenue,
    cs.avg_sale_price AS avg_price,
    -- 学员统计
    cs.student_count,
    -- 学习统计
    cs.total_learning_count AS learning_count,
    cs.total_learning_duration,
    cs.completed_count,
    -- 完课率
    CASE 
        WHEN cs.student_count > 0 THEN
            ROUND(cs.completed_count * 100.0 / cs.student_count, 2)
        ELSE 0.00
    END AS completion_rate,
    c.rating AS avg_rating,
    NOW() AS create_time,
    NOW() AS update_time
FROM dws_course_summary cs
LEFT JOIN ods_courses c ON cs.course_id = c.course_id;

-- 4. 生成学习行为日汇总（从DWS层汇总）
TRUNCATE TABLE ads_learning_daily;

INSERT INTO ads_learning_daily
SELECT 
    dt,
    student_id,
    course_id,
    learning_count,
    total_duration,
    total_duration_hour,
    completed_lessons,
    avg_progress
FROM dws_learning_summary;

-- 统计汇总结果
SELECT 'ads_order_daily' AS table_name, COUNT(*) AS record_count FROM ads_order_daily
UNION ALL
SELECT 'ads_student_profile', COUNT(*) FROM ads_student_profile
UNION ALL
SELECT 'ads_course_analysis', COUNT(*) FROM ads_course_analysis
UNION ALL
SELECT 'ads_learning_daily', COUNT(*) FROM ads_learning_daily;

