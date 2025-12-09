#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数仓数据质量监控脚本
使用 data-diff 的 DataMonitor 功能持续监控数仓数据质量
"""

import sys
import os

# 添加 data-diff 到路径
# sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../data-diff'))

try:
    from data_diff.monitor import (
        DataMonitor, MonitorRule, MonitorType, RuleOperator
    )
except ImportError:
    print("错误：请先安装 data-diff 的监控功能")
    print("cd ../../data-diff && pip install -e .")
    sys.exit(1)

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'aCqFnbtJEuaoFVjmZctE6g==',
    'database': 'education_dw',
}

MYSQL_CONN_STR = f"mysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"


def setup_monitor_rules():
    """设置监控规则"""
    monitor = DataMonitor()
    
    # 规则1：ODS → DWD 订单数据一致性监控
    rule1 = MonitorRule(
        name="ods_to_dwd_orders",
        monitor_type=MonitorType.DATA_DIFF,
        database1=MYSQL_CONN_STR,
        table1="ods_orders",
        database2=MYSQL_CONN_STR,
        table2="dwd_order_detail",
        key_columns=("order_id",),
        update_column="update_time",
        extra_columns=("order_amount", "paid_amount"),
        threshold_type="diff_percent",
        threshold_operator=RuleOperator.GT,
        threshold_value=0.1,  # 差异超过0.1%时告警
        schedule="0 2 * * *",  # 每天凌晨2点执行
        description="监控ODS到DWD订单数据一致性"
    )
    monitor.add_rule(rule1)
    
    # 规则2：ODS → DWD 学员数据一致性监控
    rule2 = MonitorRule(
        name="ods_to_dwd_students",
        monitor_type=MonitorType.DATA_DIFF,
        database1=MYSQL_CONN_STR,
        table1="ods_students",
        database2=MYSQL_CONN_STR,
        table2="dwd_student_detail",
        key_columns=("student_id",),
        threshold_type="diff_count",
        threshold_operator=RuleOperator.GT,
        threshold_value=10,  # 差异超过10条时告警
        schedule="0 2 * * *",
        description="监控ODS到DWD学员数据一致性"
    )
    monitor.add_rule(rule2)
    
    # 规则3：DWD → DWS 订单汇总监控（行数检查）
    rule3 = MonitorRule(
        name="dwd_to_dws_orders_count",
        monitor_type=MonitorType.ROW_COUNT,
        database1=MYSQL_CONN_STR,
        table1="dwd_order_detail",
        threshold_type="row_count_diff",
        threshold_operator=RuleOperator.GT,
        threshold_value=100,  # 行数差异超过100时告警
        schedule="0 3 * * *",  # 每天凌晨3点执行
        description="监控DWD到DWS订单数据行数"
    )
    monitor.add_rule(rule3)
    
    return monitor


def main():
    """主函数"""
    print("设置数据质量监控规则...")
    monitor = setup_monitor_rules()
    
    print(f"已添加 {len(monitor.rules)} 条监控规则")
    
    # 手动执行一次所有监控
    print("\n执行数据质量检查...")
    for rule_name in monitor.rules.keys():
        print(f"\n执行监控: {rule_name}")
        try:
            result = monitor.run_monitor(rule_name)
            if result.success:
                print(f"  ✓ 通过 - 差异: {result.diff_count} ({result.diff_percent:.2f}%)")
            else:
                print(f"  ✗ 失败 - 差异: {result.diff_count} ({result.diff_percent:.2f}%)")
                print(f"  告警: {result.message if hasattr(result, 'message') else '数据差异超过阈值'}")
        except Exception as e:
            print(f"  ✗ 执行失败: {str(e)}")
    
    print("\n监控规则设置完成！")
    print("可以使用 MonitorScheduler 启动定时监控")


if __name__ == '__main__':
    main()

