#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在线教育平台数仓 - 测试数据生成脚本
最大表数据量：1万条（订单表）
"""

import pymysql
import random
from datetime import datetime, timedelta
import string

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'aCqFnbtJEuaoFVjmZctE6g==',
    'database': 'education_dw',
    'charset': 'utf8mb4'
}

# 省份城市数据
PROVINCES_CITIES = {
    '北京市': ['东城区', '西城区', '朝阳区', '海淀区'],
    '上海市': ['黄浦区', '徐汇区', '长宁区', '静安区'],
    '广东省': ['广州市', '深圳市', '珠海市', '佛山市'],
    '浙江省': ['杭州市', '宁波市', '温州市', '嘉兴市'],
    '江苏省': ['南京市', '苏州市', '无锡市', '常州市'],
    '四川省': ['成都市', '绵阳市', '德阳市', '乐山市'],
    '湖北省': ['武汉市', '宜昌市', '襄阳市', '荆州市'],
    '山东省': ['济南市', '青岛市', '烟台市', '潍坊市'],
    '河南省': ['郑州市', '洛阳市', '开封市', '新乡市'],
    '湖南省': ['长沙市', '株洲市', '湘潭市', '衡阳市'],
}

# 课程分类
COURSE_CATEGORIES = [
    ('编程开发', 'Python', 'Java', '前端开发', '移动开发'),
    ('设计创意', 'UI设计', '平面设计', '视频剪辑', '3D建模'),
    ('职业技能', '数据分析', '产品经理', '运营', '市场营销'),
    ('语言学习', '英语', '日语', '韩语', '法语'),
    ('考试认证', '公务员', '教师资格', '会计', '建造师'),
]

# 常见姓氏和名字
SURNAMES = ['王', '李', '张', '刘', '陈', '杨', '赵', '黄', '周', '吴', '徐', '孙', '胡', '朱', '高', '林', '何', '郭', '马', '罗']
GIVEN_NAMES = ['伟', '芳', '娜', '秀英', '敏', '静', '丽', '强', '磊', '军', '洋', '勇', '艳', '杰', '娟', '涛', '明', '超', '秀兰', '霞', '平', '刚', '桂英']

def generate_phone():
    """生成手机号"""
    prefix = random.choice(['130', '131', '132', '133', '134', '135', '136', '137', '138', '139',
                           '150', '151', '152', '153', '155', '156', '157', '158', '159',
                           '180', '181', '182', '183', '184', '185', '186', '187', '188', '189'])
    return prefix + ''.join([str(random.randint(0, 9)) for _ in range(8)])

def generate_email(name):
    """生成邮箱"""
    domains = ['gmail.com', 'qq.com', '163.com', 'sina.com', 'outlook.com', 'foxmail.com']
    return f"{name.lower()}{random.randint(100, 999)}@{random.choice(domains)}"

def mask_phone(phone):
    """手机号脱敏"""
    if not phone or len(phone) != 11:
        return phone
    return phone[:3] + '****' + phone[7:]

def mask_email(email):
    """邮箱脱敏"""
    if not email or '@' not in email:
        return email
    name, domain = email.split('@')
    if len(name) <= 2:
        masked_name = name[0] + '*'
    else:
        masked_name = name[0] + '*' * (len(name) - 2) + name[-1]
    return f"{masked_name}@{domain}"

def generate_students(conn, count=5000):
    """生成学员数据"""
    cursor = conn.cursor()
    print(f"开始生成 {count} 条学员数据...")
    
    provinces = list(PROVINCES_CITIES.keys())
    
    for i in range(1, count + 1):
        surname = random.choice(SURNAMES)
        given_name = random.choice(GIVEN_NAMES)
        if random.random() < 0.3:
            given_name += random.choice(GIVEN_NAMES)
        student_name = surname + given_name
        
        phone = generate_phone()
        email = generate_email(student_name)
        gender = random.choice([1, 2])
        age = random.randint(18, 60)
        
        province = random.choice(provinces)
        city = random.choice(PROVINCES_CITIES[province])
        district = random.choice(['区1', '区2', '区3'])
        
        register_time = datetime.now() - timedelta(days=random.randint(0, 365))
        vip_level = random.choices([0, 1, 2, 3], weights=[60, 25, 10, 5])[0]
        status = random.choices([0, 1], weights=[5, 95])[0]
        
        sql = """
        INSERT INTO ods_students 
        (student_id, student_name, phone, email, gender, age, province, city, district, 
         register_time, vip_level, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (i, student_name, phone, email, gender, age, province, city, 
                            district, register_time, vip_level, status))
        
        if i % 1000 == 0:
            conn.commit()
            print(f"已生成 {i} 条学员数据")
    
    conn.commit()
    cursor.close()
    print(f"学员数据生成完成，共 {count} 条")

def generate_courses(conn, count=500):
    """生成课程数据"""
    cursor = conn.cursor()
    print(f"开始生成 {count} 条课程数据...")
    
    teachers = ['张老师', '李老师', '王老师', '刘老师', '陈老师', '杨老师', '赵老师', '黄老师']
    
    category_id = 1
    for i in range(1, count + 1):
        category_name, *sub_categories = random.choice(COURSE_CATEGORIES)
        sub_category = random.choice(sub_categories)
        course_name = f"{sub_category}实战课程{i}"
        
        teacher = random.choice(teachers)
        price = random.choice([99, 199, 299, 399, 499, 599, 699, 799, 999])
        original_price = price + random.randint(50, 200)
        
        course_type = random.choice([1, 2, 3])
        difficulty_level = random.choice([1, 2, 3])
        total_lessons = random.randint(10, 50)
        total_duration = total_lessons * random.randint(30, 90)
        student_count = random.randint(0, 5000)
        rating = round(random.uniform(3.5, 5.0), 2)
        status = random.choices([0, 1], weights=[10, 90])[0]
        
        create_time = datetime.now() - timedelta(days=random.randint(0, 180))
        
        sql = """
        INSERT INTO ods_courses 
        (course_id, course_name, category_id, category_name, teacher_id, teacher_name,
         price, original_price, course_type, difficulty_level, total_lessons, total_duration,
         student_count, rating, status, create_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (i, course_name, category_id, category_name, 
                            random.randint(1, 100), teacher, price, original_price,
                            course_type, difficulty_level, total_lessons, total_duration,
                            student_count, rating, status, create_time))
        
        if i % 10 == 0:
            category_id = (category_id % len(COURSE_CATEGORIES)) + 1
        
        if i % 100 == 0:
            conn.commit()
            print(f"已生成 {i} 条课程数据")
    
    conn.commit()
    cursor.close()
    print(f"课程数据生成完成，共 {count} 条")

def generate_orders(conn, count=10000):
    """生成订单数据（最大表，1万条）"""
    cursor = conn.cursor()
    print(f"开始生成 {count} 条订单数据...")
    
    # 获取学员和课程ID范围
    cursor.execute("SELECT MIN(student_id), MAX(student_id) FROM ods_students")
    min_student_id, max_student_id = cursor.fetchone()
    
    cursor.execute("SELECT MIN(course_id), MAX(course_id) FROM ods_courses WHERE status=1")
    min_course_id, max_course_id = cursor.fetchone()
    
    for i in range(1, count + 1):
        order_no = f"EDU{datetime.now().strftime('%Y%m%d')}{i:06d}"
        student_id = random.randint(min_student_id, max_student_id)
        course_id = random.randint(min_course_id, max_course_id)
        
        # 获取课程价格
        cursor.execute("SELECT price FROM ods_courses WHERE course_id = %s", (course_id,))
        result = cursor.fetchone()
        if result:
            course_price = float(result[0])
        else:
            course_price = random.choice([99, 199, 299, 399, 499])
        
        # 生成订单金额和优惠
        discount_rate = random.choices([0, 0.1, 0.2, 0.3], weights=[40, 30, 20, 10])[0]
        order_amount = course_price
        discount_amount = round(order_amount * discount_rate, 2)
        paid_amount = round(order_amount - discount_amount, 2)
        
        payment_method = random.choice([1, 2, 3])
        order_status = random.choices([0, 1, 2, 3], weights=[10, 80, 5, 5])[0]
        
        order_time = datetime.now() - timedelta(days=random.randint(0, 365))
        pay_time = None
        cancel_time = None
        
        if order_status == 1:  # 已支付
            pay_time = order_time + timedelta(minutes=random.randint(1, 60))
        elif order_status == 2:  # 已取消
            cancel_time = order_time + timedelta(hours=random.randint(1, 24))
        elif order_status == 3:  # 已退款
            pay_time = order_time + timedelta(minutes=random.randint(1, 60))
            cancel_time = pay_time + timedelta(days=random.randint(1, 7))
        
        sql = """
        INSERT INTO ods_orders 
        (order_id, order_no, student_id, course_id, order_amount, discount_amount, paid_amount,
         payment_method, order_status, order_time, pay_time, cancel_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (i, order_no, student_id, course_id, order_amount, discount_amount,
                            paid_amount, payment_method, order_status, order_time, pay_time, cancel_time))
        
        if i % 1000 == 0:
            conn.commit()
            print(f"已生成 {i} 条订单数据")
    
    conn.commit()
    cursor.close()
    print(f"订单数据生成完成，共 {count} 条")

def generate_learning_records(conn, count=8000):
    """生成学习记录数据"""
    cursor = conn.cursor()
    print(f"开始生成 {count} 条学习记录数据...")
    
    # 获取已支付订单的学员和课程
    cursor.execute("""
        SELECT DISTINCT student_id, course_id 
        FROM ods_orders 
        WHERE order_status = 1 
        LIMIT 2000
    """)
    student_courses = cursor.fetchall()
    
    if not student_courses:
        print("没有找到已支付订单，无法生成学习记录")
        return
    
    for i in range(1, count + 1):
        student_id, course_id = random.choice(student_courses)
        lesson_id = random.randint(1, 50)
        lesson_name = f"第{lesson_id}课时"
        
        learning_duration = random.randint(10, 120)
        progress = random.uniform(0, 100)
        if progress >= 100:
            is_completed = 1
            progress = 100.00
        else:
            is_completed = 0
        
        learning_time = datetime.now() - timedelta(days=random.randint(0, 180))
        
        sql = """
        INSERT INTO ods_learning_records 
        (record_id, student_id, course_id, lesson_id, lesson_name, learning_duration,
         progress, is_completed, learning_time)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (i, student_id, course_id, lesson_id, lesson_name,
                            learning_duration, round(progress, 2), is_completed, learning_time))
        
        if i % 1000 == 0:
            conn.commit()
            print(f"已生成 {i} 条学习记录数据")
    
    conn.commit()
    cursor.close()
    print(f"学习记录数据生成完成，共 {count} 条")

def main():
    """主函数"""
    try:
        conn = pymysql.connect(**DB_CONFIG)
        print("数据库连接成功")
        
        # 生成数据
        generate_students(conn, 5000)
        generate_courses(conn, 500)
        generate_orders(conn, 10000)  # 最大表
        generate_learning_records(conn, 8000)
        
        print("\n所有测试数据生成完成！")
        print("数据量统计：")
        print("  - 学员表：5,000 条")
        print("  - 课程表：500 条")
        print("  - 订单表：10,000 条（最大表）")
        print("  - 学习记录表：8,000 条")
        
        conn.close()
    except Exception as e:
        print(f"错误：{e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()



