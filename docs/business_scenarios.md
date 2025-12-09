# 业务场景示例

本文档提供了在线教育平台数仓的常见业务场景SQL查询示例。

## 1. 订单分析场景

### 1.1 最近7天订单GMV趋势

```sql
SELECT 
    dt AS 日期,
    order_count AS 订单数,
    paid_order_count AS 已支付订单数,
    total_gmv AS 总GMV,
    paid_gmv AS 已支付GMV,
    avg_order_amount AS 平均订单金额,
    cancel_rate AS 取消率
FROM ads_order_daily
WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY dt DESC;
```

### 1.2 月度GMV汇总

```sql
SELECT 
    YEAR(dt) AS 年份,
    MONTH(dt) AS 月份,
    SUM(order_count) AS 总订单数,
    SUM(paid_order_count) AS 已支付订单数,
    SUM(total_gmv) AS 总GMV,
    SUM(paid_gmv) AS 已支付GMV,
    ROUND(AVG(avg_order_amount), 2) AS 平均订单金额
FROM ads_order_daily
GROUP BY YEAR(dt), MONTH(dt)
ORDER BY 年份 DESC, 月份 DESC;
```

### 1.3 支付方式分布

```sql
SELECT 
    payment_method_desc AS 支付方式,
    COUNT(*) AS 订单数,
    SUM(paid_amount) AS 总金额,
    ROUND(AVG(paid_amount), 2) AS 平均金额,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dwd_order_detail WHERE is_paid = 1), 2) AS 占比
FROM dwd_order_detail
WHERE is_paid = 1
GROUP BY payment_method_desc
ORDER BY 订单数 DESC;
```

## 2. 学员分析场景

### 2.1 学员地域分布TOP10

```sql
SELECT 
    province AS 省份,
    city AS 城市,
    COUNT(*) AS 学员数,
    SUM(total_consumption) AS 总消费,
    ROUND(AVG(total_consumption), 2) AS 平均消费,
    SUM(total_courses) AS 总购买课程数
FROM ads_student_profile
GROUP BY province, city
ORDER BY 学员数 DESC
LIMIT 10;
```

### 2.2 VIP学员消费分析

```sql
SELECT 
    vip_level_desc AS VIP等级,
    COUNT(*) AS 学员数,
    SUM(total_consumption) AS 总消费,
    ROUND(AVG(total_consumption), 2) AS 平均消费,
    ROUND(AVG(total_courses), 2) AS 平均购买课程数,
    ROUND(AVG(completion_rate), 2) AS 平均完课率
FROM ads_student_profile
GROUP BY vip_level_desc
ORDER BY 
    CASE vip_level_desc
        WHEN '钻石' THEN 1
        WHEN '金卡' THEN 2
        WHEN '银卡' THEN 3
        WHEN '普通' THEN 4
    END;
```

### 2.3 高价值学员（消费TOP100）

```sql
SELECT 
    student_id AS 学员ID,
    student_name AS 学员姓名,
    province AS 省份,
    city AS 城市,
    vip_level_desc AS VIP等级,
    total_orders AS 总订单数,
    total_consumption AS 总消费,
    total_courses AS 购买课程数,
    completion_rate AS 完课率
FROM ads_student_profile
ORDER BY total_consumption DESC
LIMIT 100;
```

## 3. 课程分析场景

### 3.1 课程销售TOP10

```sql
SELECT 
    course_name AS 课程名称,
    category_name AS 分类,
    teacher_name AS 讲师,
    price AS 价格,
    sales_count AS 销售数量,
    paid_sales_count AS 已支付数量,
    total_revenue AS 总营收,
    student_count AS 学员数,
    completion_rate AS 完课率,
    avg_rating AS 平均评分
FROM ads_course_analysis
ORDER BY sales_count DESC
LIMIT 10;
```

### 3.2 课程分类销售分析

```sql
SELECT 
    category_name AS 课程分类,
    COUNT(*) AS 课程数,
    SUM(sales_count) AS 总销售数,
    SUM(total_revenue) AS 总营收,
    ROUND(AVG(price), 2) AS 平均价格,
    ROUND(AVG(completion_rate), 2) AS 平均完课率,
    ROUND(AVG(avg_rating), 2) AS 平均评分
FROM ads_course_analysis
GROUP BY category_name
ORDER BY 总营收 DESC;
```

### 3.3 高完课率课程（完课率>80%）

```sql
SELECT 
    course_name AS 课程名称,
    category_name AS 分类,
    student_count AS 学员数,
    completed_count AS 完成数,
    completion_rate AS 完课率,
    total_learning_duration AS 总学习时长,
    avg_rating AS 平均评分
FROM ads_course_analysis
WHERE completion_rate >= 80
ORDER BY completion_rate DESC, student_count DESC;
```

## 4. 学习行为分析场景

### 4.1 学员学习活跃度（最近30天）

```sql
SELECT 
    student_id AS 学员ID,
    COUNT(DISTINCT dt) AS 学习天数,
    SUM(learning_count) AS 总学习次数,
    ROUND(SUM(total_duration_hour), 2) AS 总学习时长_小时,
    SUM(completed_lessons) AS 完成课时数
FROM ads_learning_daily
WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY student_id
ORDER BY 学习天数 DESC, 总学习时长_小时 DESC
LIMIT 50;
```

### 4.2 每日学习时长趋势

```sql
SELECT 
    dt AS 日期,
    COUNT(DISTINCT student_id) AS 活跃学员数,
    SUM(learning_count) AS 总学习次数,
    ROUND(SUM(total_duration_hour), 2) AS 总学习时长_小时,
    ROUND(AVG(total_duration_hour), 2) AS 平均学习时长_小时
FROM ads_learning_daily
WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY dt
ORDER BY dt DESC;
```

## 5. 综合分析场景

### 5.1 订单转化漏斗分析

```sql
SELECT 
    '总订单数' AS 指标,
    COUNT(*) AS 数量
FROM dwd_order_detail
UNION ALL
SELECT 
    '已支付订单数',
    COUNT(*)
FROM dwd_order_detail
WHERE is_paid = 1
UNION ALL
SELECT 
    '已取消订单数',
    COUNT(*)
FROM dwd_order_detail
WHERE order_status = 2
UNION ALL
SELECT 
    '已退款订单数',
    COUNT(*)
FROM dwd_order_detail
WHERE order_status = 3;
```

### 5.2 学员生命周期分析

```sql
SELECT 
    CASE 
        WHEN register_days <= 30 THEN '新学员（30天内）'
        WHEN register_days <= 90 THEN '成长学员（31-90天）'
        WHEN register_days <= 180 THEN '成熟学员（91-180天）'
        ELSE '老学员（180天以上）'
    END AS 学员阶段,
    COUNT(*) AS 学员数,
    ROUND(AVG(total_consumption), 2) AS 平均消费,
    ROUND(AVG(total_courses), 2) AS 平均购买课程数,
    ROUND(AVG(completion_rate), 2) AS 平均完课率
FROM ads_student_profile
GROUP BY 
    CASE 
        WHEN register_days <= 30 THEN '新学员（30天内）'
        WHEN register_days <= 90 THEN '成长学员（31-90天）'
        WHEN register_days <= 180 THEN '成熟学员（91-180天）'
        ELSE '老学员（180天以上）'
    END
ORDER BY 
    CASE 
        WHEN register_days <= 30 THEN 1
        WHEN register_days <= 90 THEN 2
        WHEN register_days <= 180 THEN 3
        ELSE 4
    END;
```

### 5.3 课程质量评估（综合评分）

```sql
SELECT 
    course_name AS 课程名称,
    category_name AS 分类,
    sales_count AS 销售数,
    student_count AS 学员数,
    completion_rate AS 完课率,
    avg_rating AS 评分,
    -- 综合评分 = 完课率*0.4 + 评分*0.3 + 销售数归一化*0.3
    ROUND(
        completion_rate * 0.4 + 
        avg_rating * 20 * 0.3 + 
        (sales_count / (SELECT MAX(sales_count) FROM ads_course_analysis)) * 100 * 0.3,
        2
    ) AS 综合评分
FROM ads_course_analysis
WHERE student_count > 0
ORDER BY 综合评分 DESC
LIMIT 20;
```

## 6. 数据质量检查

### 6.1 检查数据完整性

```sql
-- 检查订单数据完整性
SELECT 
    '订单表' AS 表名,
    COUNT(*) AS 总记录数,
    SUM(CASE WHEN order_no IS NULL THEN 1 ELSE 0 END) AS 订单号缺失,
    SUM(CASE WHEN student_id IS NULL THEN 1 ELSE 0 END) AS 学员ID缺失,
    SUM(CASE WHEN course_id IS NULL THEN 1 ELSE 0 END) AS 课程ID缺失
FROM dwd_order_detail;
```

### 6.2 检查数据一致性

```sql
-- 检查订单金额一致性
SELECT 
    '金额不一致' AS 问题类型,
    COUNT(*) AS 问题数量
FROM dwd_order_detail
WHERE ABS(order_amount - discount_amount - paid_amount) > 0.01;
```

