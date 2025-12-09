#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数仓数据质量检查脚本
使用 data-diff 验证 ETL 过程中的数据一致性
"""

import sys
import os
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass

# 添加 data-diff 到路径（如果不在同一项目）
# sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../data-diff'))

try:
    from data_diff import connect_to_table, diff_tables, Algorithm
    from data_diff.diff_tables import DiffResultWrapper
except ImportError:
    print("错误：请先安装 data-diff")
    print("pip install data-diff 或 cd ../../data-diff && pip install -e .")
    sys.exit(1)

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'aCqFnbtJEuaoFVjmZctE6g==',
    'database': 'education_dw',
    'charset': 'utf8mb4'
}

# MySQL连接字符串
MYSQL_CONN_STR = f"mysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"


@dataclass
class QualityCheckResult:
    """数据质量检查结果"""
    check_name: str
    success: bool
    diff_count: int
    diff_percent: float
    source_count: int
    target_count: int
    message: str
    details: Optional[Dict] = None


class DataQualityChecker:
    """数据质量检查器"""
    
    def __init__(self, db_conn_str: str = MYSQL_CONN_STR):
        self.db_conn_str = db_conn_str
    
    def check_ods_to_dwd_orders(self) -> QualityCheckResult:
        """检查 ODS 到 DWD 订单数据一致性"""
        print("检查 ODS → DWD 订单数据...")
        
        try:
            # 连接ODS层订单表
            ods_table = connect_to_table(
                self.db_conn_str,
                "ods_orders",
                key_columns=("order_id",),
                extra_columns=("order_amount", "paid_amount", "order_status")
            )
            
            # 连接DWD层订单表
            dwd_table = connect_to_table(
                self.db_conn_str,
                "dwd_order_detail",
                key_columns=("order_id",),
                extra_columns=("order_amount", "paid_amount", "order_status")
            )
            
            # 执行差异对比
            diff_result: DiffResultWrapper = diff_tables(
                ods_table,
                dwd_table,
                algorithm=Algorithm.JOINDIFF,
                extra_columns=("order_amount", "paid_amount", "order_status")
            )
            
            stats = diff_result.get_stats_dict()
            diff_count = stats.get("total", 0)
            source_count = stats.get("rows_A", 0)
            target_count = stats.get("rows_B", 0)
            
            max_rows = max(source_count, target_count) if (source_count or target_count) else 1
            diff_percent = (diff_count / max_rows * 100) if max_rows > 0 else 0.0
            
            success = diff_count == 0 and source_count == target_count
            
            return QualityCheckResult(
                check_name="ODS → DWD 订单数据",
                success=success,
                diff_count=diff_count,
                diff_percent=diff_percent,
                source_count=source_count,
                target_count=target_count,
                message=f"ODS订单数: {source_count}, DWD订单数: {target_count}, 差异: {diff_count} ({diff_percent:.2f}%)",
                details=stats
            )
        except Exception as e:
            return QualityCheckResult(
                check_name="ODS → DWD 订单数据",
                success=False,
                diff_count=0,
                diff_percent=0.0,
                source_count=0,
                target_count=0,
                message=f"检查失败: {str(e)}"
            )
    
    def check_ods_to_dwd_students(self) -> QualityCheckResult:
        """检查 ODS 到 DWD 学员数据一致性（数量）"""
        print("检查 ODS → DWD 学员数据...")
        
        try:
            ods_table = connect_to_table(
                self.db_conn_str,
                "ods_students",
                key_columns=("student_id",)
            )
            
            dwd_table = connect_to_table(
                self.db_conn_str,
                "dwd_student_detail",
                key_columns=("student_id",)
            )
            
            diff_result: DiffResultWrapper = diff_tables(
                ods_table,
                dwd_table,
                algorithm=Algorithm.JOINDIFF
            )
            
            stats = diff_result.get_stats_dict()
            diff_count = stats.get("total", 0)
            source_count = stats.get("rows_A", 0)
            target_count = stats.get("rows_B", 0)
            
            max_rows = max(source_count, target_count) if (source_count or target_count) else 1
            diff_percent = (diff_count / max_rows * 100) if max_rows > 0 else 0.0
            
            success = diff_count == 0 and source_count == target_count
            
            return QualityCheckResult(
                check_name="ODS → DWD 学员数据",
                success=success,
                diff_count=diff_count,
                diff_percent=diff_percent,
                source_count=source_count,
                target_count=target_count,
                message=f"ODS学员数: {source_count}, DWD学员数: {target_count}, 差异: {diff_count} ({diff_percent:.2f}%)",
                details=stats
            )
        except Exception as e:
            return QualityCheckResult(
                check_name="ODS → DWD 学员数据",
                success=False,
                diff_count=0,
                diff_percent=0.0,
                source_count=0,
                target_count=0,
                message=f"检查失败: {str(e)}"
            )
    
    def check_dwd_to_dws_orders(self) -> QualityCheckResult:
        """检查 DWD 到 DWS 订单汇总数据一致性"""
        print("检查 DWD → DWS 订单汇总数据...")
        
        try:
            # 从DWD层汇总订单数据
            # 这里需要先执行一个汇总查询，然后对比DWS层的数据
            # 简化处理：只检查订单数量是否一致
            
            dwd_table = connect_to_table(
                self.db_conn_str,
                "dwd_order_detail",
                key_columns=("order_id",)
            )
            
            # DWS层按日期+地区+分类汇总，所以需要检查汇总后的总数
            # 这里简化处理，只检查是否有数据
            from data_diff.databases import connect_to_database
            db = connect_to_database(self.db_conn_str)
            
            # 获取DWD层订单总数
            dwd_count = db.query("SELECT COUNT(*) as cnt FROM dwd_order_detail", int)
            
            # 获取DWS层订单汇总总数
            dws_count = db.query("SELECT SUM(order_count) as cnt FROM dws_order_summary", int)
            
            diff_count = abs(dwd_count - dws_count)
            max_rows = max(dwd_count, dws_count) if (dwd_count or dws_count) else 1
            diff_percent = (diff_count / max_rows * 100) if max_rows > 0 else 0.0
            
            # 允许一定误差（因为DWS是汇总数据）
            success = diff_percent < 5.0  # 允许5%的误差
            
            return QualityCheckResult(
                check_name="DWD → DWS 订单汇总",
                success=success,
                diff_count=diff_count,
                diff_percent=diff_percent,
                source_count=dwd_count,
                target_count=dws_count,
                message=f"DWD订单数: {dwd_count}, DWS汇总订单数: {dws_count}, 差异: {diff_count} ({diff_percent:.2f}%)",
            )
        except Exception as e:
            return QualityCheckResult(
                check_name="DWD → DWS 订单汇总",
                success=False,
                diff_count=0,
                diff_percent=0.0,
                source_count=0,
                target_count=0,
                message=f"检查失败: {str(e)}"
            )
    
    def check_dws_to_ads_orders(self) -> QualityCheckResult:
        """检查 DWS 到 ADS 订单日汇总数据一致性"""
        print("检查 DWS → ADS 订单日汇总数据...")
        
        try:
            from data_diff.databases import connect_to_database
            db = connect_to_database(self.db_conn_str)
            
            # 从DWS层汇总
            dws_total = db.query("SELECT SUM(order_count) as cnt FROM dws_order_summary", int)
            
            # 从ADS层汇总
            ads_total = db.query("SELECT SUM(order_count) as cnt FROM ads_order_daily", int)
            
            diff_count = abs(dws_total - ads_total)
            max_rows = max(dws_total, ads_total) if (dws_total or ads_total) else 1
            diff_percent = (diff_count / max_rows * 100) if max_rows > 0 else 0.0
            
            success = diff_percent < 1.0  # 允许1%的误差
            
            return QualityCheckResult(
                check_name="DWS → ADS 订单日汇总",
                success=success,
                diff_count=diff_count,
                diff_percent=diff_percent,
                source_count=dws_total,
                target_count=ads_total,
                message=f"DWS订单总数: {dws_total}, ADS订单总数: {ads_total}, 差异: {diff_count} ({diff_percent:.2f}%)",
            )
        except Exception as e:
            return QualityCheckResult(
                check_name="DWS → ADS 订单日汇总",
                success=False,
                diff_count=0,
                diff_percent=0.0,
                source_count=0,
                target_count=0,
                message=f"检查失败: {str(e)}"
            )
    
    def run_all_checks(self) -> List[QualityCheckResult]:
        """运行所有数据质量检查"""
        results = []
        
        # ODS → DWD 检查
        results.append(self.check_ods_to_dwd_orders())
        results.append(self.check_ods_to_dwd_students())
        
        # DWD → DWS 检查
        results.append(self.check_dwd_to_dws_orders())
        
        # DWS → ADS 检查
        results.append(self.check_dws_to_ads_orders())
        
        return results
    
    def print_report(self, results: List[QualityCheckResult]):
        """打印检查报告"""
        print("\n" + "="*80)
        print("数据质量检查报告")
        print("="*80)
        
        success_count = sum(1 for r in results if r.success)
        total_count = len(results)
        
        for result in results:
            status = "✓ 通过" if result.success else "✗ 失败"
            print(f"\n[{status}] {result.check_name}")
            print(f"  {result.message}")
            if result.details:
                print(f"  详细信息: {result.details}")
        
        print("\n" + "="*80)
        print(f"总计: {success_count}/{total_count} 检查通过")
        print("="*80)
        
        return success_count == total_count


def main():
    """主函数"""
    checker = DataQualityChecker()
    results = checker.run_all_checks()
    all_passed = checker.print_report(results)
    
    # 如果有检查失败，返回非零退出码
    sys.exit(0 if all_passed else 1)


if __name__ == '__main__':
    main()

