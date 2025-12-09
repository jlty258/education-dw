# Data-Diff 与数仓集成方案

## 📋 概述

将 `data-diff` 项目与 `education-dw` 数仓集成，实现数据质量监控、ETL验证和跨层数据一致性检查。

## 🎯 应用场景

### 1. ETL数据质量检查

在数据流转过程中验证数据一致性：
- **ODS → DWD**：验证清洗后的数据是否正确
- **DWD → DWS**：验证汇总数据是否准确
- **DWS → ADS**：验证应用层数据是否完整

### 2. 跨层数据对比

对比不同层级之间的数据差异：
- 订单数量一致性检查
- 金额汇总准确性验证
- 学员数据完整性检查

### 3. 数据完整性监控

持续监控数仓各层数据：
- 每日自动检查数据一致性
- 异常数据告警
- 数据质量报告

## 🔧 集成方案

### 方案1：ETL验证脚本（推荐）

在ETL执行后自动验证数据质量。

**使用方式：**

```bash
# 安装 data-diff
cd ../../data-diff
pip install -e .

# 执行数据质量检查
cd ../../education-dw
python3 scripts/data_quality_check.py
```

**功能：**
- ✅ 检查 ODS → DWD 订单数据一致性
- ✅ 检查 ODS → DWD 学员数据一致性
- ✅ 检查 DWD → DWS 订单汇总准确性
- ✅ 检查 DWS → ADS 订单日汇总一致性

**输出示例：**

```
检查 ODS → DWD 订单数据...
检查 ODS → DWD 学员数据...
检查 DWD → DWS 订单汇总数据...
检查 DWS → ADS 订单日汇总数据...

================================================================================
数据质量检查报告
================================================================================

[✓ 通过] ODS → DWD 订单数据
  ODS订单数: 10000, DWD订单数: 10000, 差异: 0 (0.00%)

[✓ 通过] ODS → DWD 学员数据
  ODS学员数: 5000, DWD学员数: 5000, 差异: 0 (0.00%)

[✓ 通过] DWD → DWS 订单汇总
  DWD订单数: 10000, DWS汇总订单数: 10000, 差异: 0 (0.00%)

[✓ 通过] DWS → ADS 订单日汇总
  DWS订单总数: 10000, ADS订单总数: 10000, 差异: 0 (0.00%)

================================================================================
总计: 4/4 检查通过
================================================================================
```

### 方案2：数据质量监控

使用DataMonitor持续监控数仓数据质量。

**使用方式：**

```bash
# 设置监控规则
python3 scripts/data_quality_monitor.py

# 启动定时监控（需要配置调度器）
# 详见 data-diff 的 MonitorScheduler 文档
```

**功能：**
- ✅ 定时执行数据质量检查
- ✅ 自动告警（邮件、钉钉、Webhook等）
- ✅ 历史记录保存
- ✅ 灵活的阈值规则

**监控规则示例：**

```python
# ODS → DWD 订单数据一致性监控
# 差异超过0.1%时告警，每天凌晨2点执行

# ODS → DWD 学员数据一致性监控
# 差异超过10条时告警，每天凌晨2点执行

# DWD → DWS 订单汇总监控
# 行数差异超过100时告警，每天凌晨3点执行
```

### 方案3：部署集成

将数据质量检查集成到部署流程中。

**已集成到 `deploy.sh`：**

部署脚本会自动执行数据质量检查（如果已安装data-diff）。

## 📊 检查项说明

### 1. ODS → DWD 检查

**检查内容：**
- 订单数据：订单ID、金额、状态一致性
- 学员数据：学员ID、基本信息一致性

**检查方法：**
- 使用 `JOINDIFF` 算法（同库对比）
- 对比主键和关键字段

### 2. DWD → DWS 检查

**检查内容：**
- 订单汇总数量一致性
- 允许一定误差（汇总可能有多对一关系）

**检查方法：**
- 汇总DWD层数据
- 对比DWS层汇总结果
- 允许5%的误差范围

### 3. DWS → ADS 检查

**检查内容：**
- 订单日汇总数据一致性
- 汇总金额准确性

**检查方法：**
- 汇总DWS层数据
- 对比ADS层汇总结果
- 允许1%的误差范围

## 🚀 快速开始

### 1. 安装 data-diff

```bash
cd /root/joyday/sqlwing/data-diff
pip install -e .
```

### 2. 执行数据质量检查

```bash
cd /root/joyday/sqlwing/education-dw
python3 scripts/data_quality_check.py
```

### 3. 设置监控规则（可选）

```bash
python3 scripts/data_quality_monitor.py
```

## 📝 配置文件

可以创建配置文件 `scripts/data_quality_config.yaml`：

```yaml
database:
  host: localhost
  port: 3306
  user: root
  password: aCqFnbtJEuaoFVjmZctE6g==
  database: education_dw

checks:
  - name: ods_to_dwd_orders
    source_table: ods_orders
    target_table: dwd_order_detail
    key_columns: [order_id]
    extra_columns: [order_amount, paid_amount]
    threshold_percent: 0.1
    
  - name: ods_to_dwd_students
    source_table: ods_students
    target_table: dwd_student_detail
    key_columns: [student_id]
    threshold_count: 10
```

## 🔔 告警配置

### 邮件告警

```python
from data_diff.monitor import AlertManager, AlertChannel

alert_manager = AlertManager()
alert_manager.add_channel(
    AlertChannel.EMAIL,
    config={
        "smtp_host": "smtp.example.com",
        "smtp_port": 587,
        "smtp_user": "alerts@example.com",
        "smtp_password": "password",
        "from_email": "data-monitor@example.com",
        "to_emails": ["team@example.com"]
    }
)
```

### 钉钉告警

```python
alert_manager.add_channel(
    AlertChannel.DINGTALK,
    config={
        "webhook_url": "https://oapi.dingtalk.com/robot/send?access_token=xxx"
    }
)
```

## 📈 最佳实践

1. **ETL后立即检查**：在每次ETL执行后运行数据质量检查
2. **设置合理阈值**：根据业务需求设置差异阈值
3. **定期监控**：设置定时任务持续监控数据质量
4. **告警及时**：配置多渠道告警，确保问题及时发现
5. **记录历史**：保存检查历史，便于问题追溯

## 🔗 相关文档

- [data-diff 项目文档](../../data-diff/README.md)
- [DataMonitor 使用指南](../../data-diff/MONITOR_AND_MIGRATION.md)
- [业务场景SQL示例](business_scenarios.md)
