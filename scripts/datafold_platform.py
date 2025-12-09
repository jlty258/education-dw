#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Datafold-like Platform
结合 data-diff 和 datasource_guard 实现 Datafold 特性
"""

import sys
import os
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime

# 添加项目路径
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

try:
    import jsonschema
    from jsonschema import validate, ValidationError
except ImportError:
    print("错误：请安装 jsonschema")
    print("pip install jsonschema")
    sys.exit(1)

try:
    from data_diff import connect_to_table, diff_tables, Algorithm
    from data_diff.diff_tables import DiffResultWrapper
except ImportError:
    print("警告：未安装 data-diff，部分功能不可用")
    print("安装方法: cd ../../data-diff && pip install -e .")

# 数据库配置
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'aCqFnbtJEuaoFVjmZctE6g==',
    'database': 'education_dw',
}

MYSQL_CONN_STR = f"mysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"

SCHEMAS_DIR = PROJECT_ROOT / "schemas"


@dataclass
class SchemaValidationResult:
    """Schema 验证结果"""
    schema_name: str
    version: str
    valid: bool
    errors: List[str]
    warnings: List[str]


@dataclass
class DataQualityResult:
    """数据质量检查结果"""
    check_name: str
    success: bool
    diff_count: int
    diff_percent: float
    source_count: int
    target_count: int
    message: str
    timestamp: datetime


class DatafoldPlatform:
    """Datafold-like Platform
    
    结合 data-diff 和 datasource_guard 实现 Datafold 特性：
    1. Schema 验证和管理
    2. 数据质量监控
    3. 数据差异分析
    4. CI/CD 集成
    """
    
    def __init__(self, schemas_dir: Path = SCHEMAS_DIR):
        self.schemas_dir = schemas_dir
        self.schemas = {}
        self.load_schemas()
    
    def load_schemas(self):
        """加载所有 Schema"""
        if not self.schemas_dir.exists():
            print(f"警告：Schema 目录不存在: {self.schemas_dir}")
            return
        
        for schema_file in self.schemas_dir.rglob("*.json"):
            if schema_file.name == "base_schema.json":
                continue
            
            try:
                with open(schema_file, 'r', encoding='utf-8') as f:
                    schema = json.load(f)
                    schema_id = schema.get("$id", schema_file.stem)
                    self.schemas[schema_id] = schema
                    print(f"加载 Schema: {schema_id}")
            except Exception as e:
                print(f"加载 Schema 失败 {schema_file}: {e}")
    
    def validate_schema(self, schema_name: str, data: Dict) -> SchemaValidationResult:
        """验证数据是否符合 Schema"""
        schema = self.schemas.get(schema_name)
        if not schema:
            return SchemaValidationResult(
                schema_name=schema_name,
                version="unknown",
                valid=False,
                errors=[f"Schema {schema_name} 不存在"],
                warnings=[]
            )
        
        errors = []
        warnings = []
        
        try:
            validate(instance=data, schema=schema)
            valid = True
        except ValidationError as e:
            valid = False
            errors.append(str(e.message))
        except Exception as e:
            valid = False
            errors.append(f"验证失败: {str(e)}")
        
        version = schema.get("$id", "").split("/")[-1] if "$id" in schema else "v1"
        
        return SchemaValidationResult(
            schema_name=schema_name,
            version=version,
            valid=valid,
            errors=errors,
            warnings=warnings
        )
    
    def check_data_quality(self, 
                          source_table: str,
                          target_table: str,
                          key_columns: tuple = ("id",),
                          check_name: Optional[str] = None) -> DataQualityResult:
        """使用 data-diff 检查数据质量"""
        if check_name is None:
            check_name = f"{source_table} → {target_table}"
        
        try:
            source = connect_to_table(
                MYSQL_CONN_STR,
                source_table,
                key_columns=key_columns
            )
            
            target = connect_to_table(
                MYSQL_CONN_STR,
                target_table,
                key_columns=key_columns
            )
            
            diff_result: DiffResultWrapper = diff_tables(
                source,
                target,
                algorithm=Algorithm.JOINDIFF
            )
            
            stats = diff_result.get_stats_dict()
            diff_count = stats.get("total", 0)
            source_count = stats.get("rows_A", 0)
            target_count = stats.get("rows_B", 0)
            
            max_rows = max(source_count, target_count) if (source_count or target_count) else 1
            diff_percent = (diff_count / max_rows * 100) if max_rows > 0 else 0.0
            
            success = diff_count == 0 and source_count == target_count
            
            return DataQualityResult(
                check_name=check_name,
                success=success,
                diff_count=diff_count,
                diff_percent=diff_percent,
                source_count=source_count,
                target_count=target_count,
                message=f"{source_table}: {source_count}, {target_table}: {target_count}, 差异: {diff_count} ({diff_percent:.2f}%)",
                timestamp=datetime.now()
            )
        except Exception as e:
            return DataQualityResult(
                check_name=check_name,
                success=False,
                diff_count=0,
                diff_percent=0.0,
                source_count=0,
                target_count=0,
                message=f"检查失败: {str(e)}",
                timestamp=datetime.now()
            )
    
    def run_etl_validation(self) -> List[DataQualityResult]:
        """运行 ETL 数据质量验证"""
        results = []
        
        # ODS → DWD 验证
        results.append(self.check_data_quality(
            "ods_orders",
            "dwd_order_detail",
            key_columns=("order_id",),
            check_name="ODS → DWD 订单数据"
        ))
        
        results.append(self.check_data_quality(
            "ods_students",
            "dwd_student_detail",
            key_columns=("student_id",),
            check_name="ODS → DWD 学员数据"
        ))
        
        # DWD → DWS 验证（简化处理）
        # 实际应该对比汇总后的数据
        
        return results
    
    def print_quality_report(self, results: List[DataQualityResult]):
        """打印数据质量报告"""
        print("\n" + "="*80)
        print("Datafold-like Platform - 数据质量报告")
        print("="*80)
        print(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        success_count = sum(1 for r in results if r.success)
        total_count = len(results)
        
        for result in results:
            status = "✓ 通过" if result.success else "✗ 失败"
            print(f"[{status}] {result.check_name}")
            print(f"  {result.message}")
            print()
        
        print("="*80)
        print(f"总计: {success_count}/{total_count} 检查通过")
        print("="*80)
        
        return success_count == total_count


def main():
    """主函数"""
    print("Datafold-like Platform")
    print("="*80)
    
    platform = DatafoldPlatform()
    
    print(f"\n已加载 {len(platform.schemas)} 个 Schema")
    for schema_id in platform.schemas.keys():
        print(f"  - {schema_id}")
    
    # 运行 ETL 验证
    print("\n运行 ETL 数据质量验证...")
    results = platform.run_etl_validation()
    all_passed = platform.print_quality_report(results)
    
    # Schema 验证示例
    print("\n\nSchema 验证示例:")
    test_data = {
        "student_id": "1001",
        "student_name": "张三",
        "phone": "13800138000",
        "email": "zhangsan@example.com",
        "gender": "1",
        "age": "25"
    }
    
    result = platform.validate_schema(
        "https://education-dw.com/schemas/students/v1",
        test_data
    )
    
    if result.valid:
        print(f"✓ Schema 验证通过: {result.schema_name} v{result.version}")
    else:
        print(f"✗ Schema 验证失败: {result.schema_name}")
        for error in result.errors:
            print(f"  错误: {error}")
    
    sys.exit(0 if all_passed else 1)


if __name__ == '__main__':
    main()

