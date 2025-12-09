-- ============================================
-- 初始化维度表数据
-- ============================================

USE education_dw;

-- 1. 生成日期维度数据（最近1年）
TRUNCATE TABLE dim_date;

-- 使用递归CTE生成日期（MySQL 8.0+）
INSERT INTO dim_date (
    date_id, year, quarter, month, week, day, day_of_week, day_name, 
    is_weekend, is_holiday, holiday_name
)
WITH RECURSIVE date_series AS (
    SELECT DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AS date_val
    UNION ALL
    SELECT DATE_ADD(date_val, INTERVAL 1 DAY)
    FROM date_series
    WHERE date_val < CURDATE()
)
SELECT 
    date_val AS date_id,
    YEAR(date_val) AS year,
    QUARTER(date_val) AS quarter,
    MONTH(date_val) AS month,
    WEEK(date_val, 1) AS week,
    DAY(date_val) AS day,
    DAYOFWEEK(date_val) AS day_of_week,
    CASE DAYOFWEEK(date_val)
        WHEN 1 THEN '周日'
        WHEN 2 THEN '周一'
        WHEN 3 THEN '周二'
        WHEN 4 THEN '周三'
        WHEN 5 THEN '周四'
        WHEN 6 THEN '周五'
        WHEN 7 THEN '周六'
    END AS day_name,
    CASE WHEN DAYOFWEEK(date_val) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    0 AS is_holiday,  -- 节假日标记（可手动更新）
    NULL AS holiday_name
FROM date_series;

-- 2. 初始化地区维度数据
TRUNCATE TABLE dim_region;

INSERT INTO dim_region (province, city, district, region_level, parent_region_id, region_code)
VALUES
-- 省份
('北京市', NULL, NULL, 1, NULL, '110000'),
('上海市', NULL, NULL, 1, NULL, '310000'),
('广东省', NULL, NULL, 1, NULL, '440000'),
('浙江省', NULL, NULL, 1, NULL, '330000'),
('江苏省', NULL, NULL, 1, NULL, '320000'),
('四川省', NULL, NULL, 1, NULL, '510000'),
('湖北省', NULL, NULL, 1, NULL, '420000'),
('山东省', NULL, NULL, 1, NULL, '370000'),
('河南省', NULL, NULL, 1, NULL, '410000'),
('湖南省', NULL, NULL, 1, NULL, '430000'),
-- 城市
('北京市', '东城区', NULL, 2, 1, '110101'),
('北京市', '西城区', NULL, 2, 1, '110102'),
('北京市', '朝阳区', NULL, 2, 1, '110105'),
('北京市', '海淀区', NULL, 2, 1, '110108'),
('上海市', '黄浦区', NULL, 2, 2, '310101'),
('上海市', '徐汇区', NULL, 2, 2, '310104'),
('上海市', '长宁区', NULL, 2, 2, '310105'),
('上海市', '静安区', NULL, 2, 2, '310106'),
('广东省', '广州市', NULL, 2, 3, '440100'),
('广东省', '深圳市', NULL, 2, 3, '440300'),
('广东省', '珠海市', NULL, 2, 3, '440400'),
('广东省', '佛山市', NULL, 2, 3, '440600'),
('浙江省', '杭州市', NULL, 2, 4, '330100'),
('浙江省', '宁波市', NULL, 2, 4, '330200'),
('浙江省', '温州市', NULL, 2, 4, '330300'),
('浙江省', '嘉兴市', NULL, 2, 4, '330400'),
('江苏省', '南京市', NULL, 2, 5, '320100'),
('江苏省', '苏州市', NULL, 2, 5, '320500'),
('江苏省', '无锡市', NULL, 2, 5, '320200'),
('江苏省', '常州市', NULL, 2, 5, '320400'),
('四川省', '成都市', NULL, 2, 6, '510100'),
('四川省', '绵阳市', NULL, 2, 6, '510700'),
('四川省', '德阳市', NULL, 2, 6, '510600'),
('四川省', '乐山市', NULL, 2, 6, '511100'),
('湖北省', '武汉市', NULL, 2, 7, '420100'),
('湖北省', '宜昌市', NULL, 2, 7, '420500'),
('湖北省', '襄阳市', NULL, 2, 7, '420600'),
('湖北省', '荆州市', NULL, 2, 7, '421000'),
('山东省', '济南市', NULL, 2, 8, '370100'),
('山东省', '青岛市', NULL, 2, 8, '370200'),
('山东省', '烟台市', NULL, 2, 8, '370600'),
('山东省', '潍坊市', NULL, 2, 8, '370700'),
('河南省', '郑州市', NULL, 2, 9, '410100'),
('河南省', '洛阳市', NULL, 2, 9, '410300'),
('河南省', '开封市', NULL, 2, 9, '410200'),
('河南省', '新乡市', NULL, 2, 9, '410700'),
('湖南省', '长沙市', NULL, 2, 10, '430100'),
('湖南省', '株洲市', NULL, 2, 10, '430200'),
('湖南省', '湘潭市', NULL, 2, 10, '430300'),
('湖南省', '衡阳市', NULL, 2, 10, '430400');

-- 3. 初始化课程分类维度数据
TRUNCATE TABLE dim_course_category;

INSERT INTO dim_course_category (category_id, category_name, parent_category_id, category_level, sort_order, status)
VALUES
-- 一级分类
(1, '编程开发', NULL, 1, 1, 1),
(2, '设计创意', NULL, 1, 2, 1),
(3, '职业技能', NULL, 1, 3, 1),
(4, '语言学习', NULL, 1, 4, 1),
(5, '考试认证', NULL, 1, 5, 1),
-- 二级分类
(11, 'Python', 1, 2, 1, 1),
(12, 'Java', 1, 2, 2, 1),
(13, '前端开发', 1, 2, 3, 1),
(14, '移动开发', 1, 2, 4, 1),
(21, 'UI设计', 2, 2, 1, 1),
(22, '平面设计', 2, 2, 2, 1),
(23, '视频剪辑', 2, 2, 3, 1),
(24, '3D建模', 2, 2, 4, 1),
(31, '数据分析', 3, 2, 1, 1),
(32, '产品经理', 3, 2, 2, 1),
(33, '运营', 3, 2, 3, 1),
(34, '市场营销', 3, 2, 4, 1),
(41, '英语', 4, 2, 1, 1),
(42, '日语', 4, 2, 2, 1),
(43, '韩语', 4, 2, 3, 1),
(44, '法语', 4, 2, 4, 1),
(51, '公务员', 5, 2, 1, 1),
(52, '教师资格', 5, 2, 2, 1),
(53, '会计', 5, 2, 3, 1),
(54, '建造师', 5, 2, 4, 1);

-- 统计维度数据
SELECT 'dim_date' AS table_name, COUNT(*) AS record_count FROM dim_date
UNION ALL
SELECT 'dim_region', COUNT(*) FROM dim_region
UNION ALL
SELECT 'dim_course_category', COUNT(*) FROM dim_course_category
UNION ALL
SELECT 'dim_payment_method', COUNT(*) FROM dim_payment_method;

