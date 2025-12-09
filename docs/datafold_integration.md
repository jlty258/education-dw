# Datafold 特性复现方案

## 📋 概述

结合 `data-diff` 和 `datasource_guard` 两个项目，在 `education-dw` 数仓中复现 **Datafold** 的核心特性。

## 🎯 Datafold 核心特性

根据调研，Datafold 是一个统一的数据可靠性平台，核心特性包括：

1. **数据差异分析（Data Diff）** - 自动化数据比对和验证
2. **Schema 验证** - Schema 变更检测和兼容性检查
3. **数据质量监控** - 实时异常检测和告警
4. **CI/CD 集成** - 自动化测试和验证流程
5. **数据迁移验证** - 迁移过程中的数据一致性保证
6. **数据血缘** - 数据流转追踪

## 🔧 集成架构

```
┌─────────────────────────────────────────────────────────┐
│          Datafold-like Platform (education-dw)          │
└─────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐
│ data-diff    │ │datasource_  │ │ education- │
│              │ │guard        │ │ dw         │
│ - 数据对比   │ │             │ │            │
│ - 质量监控   │ │ - Schema管理│ │ - 数仓     │
│ - 差异分析   │ │ - CI/CD验证 │ │ - ETL      │
│ - 迁移验证   │ │ - 断流机制  │ │ - 数据层   │
└──────────────┘ └─────────────┘ └────────────┘
```

## 🚀 实施方案

### 1. Schema Registry（基于 datasource_guard）

**功能：**
- Schema 版本管理（Git + JSON Schema）
- Schema 变更走 PR + Review
- 自动 Schema 验证

**实现：**
- `schemas/` 目录存储所有 Schema
- JSON Schema 格式定义数据源契约
- GitHub Actions 自动验证 Schema 变更

**使用：**
```bash
# 查看 Schema
cat schemas/students/v1.json

# 提交 Schema 变更
git add schemas/students/v2.json
git commit -m "Add students schema v2"
git push
# PR 会自动触发 Schema 验证
```

### 2. 数据质量监控（基于 data-diff）

**功能：**
- ETL 数据质量检查
- 跨层数据一致性验证
- 数据差异分析

**实现：**
- `scripts/datafold_platform.py` - 统一平台脚本
- 集成 data-diff 进行数据对比
- 自动生成质量报告

**使用：**
```bash
# 运行数据质量检查
python3 scripts/datafold_platform.py
```

### 3. CI/CD 自动化验证

**功能：**
- Schema 变更自动验证
- SQL 语法检查
- 数据质量检查（可选）

**实现：**
- `.github/workflows/datafold-cicd.yml` - GitHub Actions 工作流
- PR 时自动验证 Schema
- Push 到 main 时运行数据质量检查

**流程：**
```
提交 PR → Schema 验证 → SQL 检查 → 合并
         ↓
      失败则阻止合并
```

### 4. 数据源守护（基于 datasource_guard 理念）

**功能：**
- 数据源契约管理
- 上游负责原则
- 自动验证和断流

**实现：**
- Schema Registry 管理数据源契约
- CI/CD 自动验证
- 数据质量检查作为防火墙

## 📝 详细功能

### Schema 管理

**目录结构：**
```
schemas/
├── templates/
│   └── base_schema.json      # 基础模板
├── students/
│   └── v1.json               # 学员 Schema
├── courses/
│   └── v1.json               # 课程 Schema
├── orders/
│   └── v1.json               # 订单 Schema
└── learning_records/
    └── v1.json               # 学习记录 Schema
```

**Schema 设计原则：**
1. 数据源即代码：Schema 变更走 PR
2. 上游负责：谁提供数据源，谁写契约
3. 向后兼容：新字段自动通过
4. 类型宽松：优先使用 string 类型

### 数据质量检查

**检查项：**
- ODS → DWD：订单数据、学员数据一致性
- DWD → DWS：汇总数据准确性
- DWS → ADS：应用层数据完整性

**检查方法：**
- 使用 data-diff 进行数据对比
- 支持差异百分比阈值
- 自动生成质量报告

### CI/CD 集成

**工作流：**
1. PR 提交时：
   - 验证 Schema JSON 格式
   - 检查 Schema 变更
   - 验证 SQL 语法

2. Push 到 main 时：
   - 运行数据质量检查
   - 生成质量报告
   - 发送告警（如需要）

## 🚀 快速开始

### 1. 安装依赖

```bash
# 安装 jsonschema（Schema 验证）
pip install jsonschema

# 安装 data-diff（数据质量检查）
cd ../../data-diff
pip install -e .
```

### 2. 使用 Schema Registry

```bash
# 查看现有 Schema
ls schemas/*/v*.json

# 创建新 Schema
# 参考 schemas/templates/base_schema.json
```

### 3. 运行数据质量检查

```bash
# 使用统一平台
python3 scripts/datafold_platform.py

# 或使用独立脚本
python3 scripts/data_quality_check.py
```

### 4. 配置 CI/CD

```bash
# GitHub Actions 已配置
# 提交 PR 时会自动验证 Schema
git add schemas/students/v2.json
git commit -m "Add students schema v2"
git push
```

## 📊 功能对比

| Datafold 特性 | 实现方式 | 状态 |
|--------------|---------|------|
| 数据差异分析 | data-diff | ✅ 已实现 |
| Schema 验证 | datasource_guard + JSON Schema | ✅ 已实现 |
| 数据质量监控 | data-diff + 自定义脚本 | ✅ 已实现 |
| CI/CD 集成 | GitHub Actions | ✅ 已实现 |
| 数据迁移验证 | data-diff | ✅ 已实现 |
| 数据血缘 | 文档 + 元数据 | 🟡 部分实现 |

## 🔗 相关文档

- [数据质量集成方案](data_quality_integration.md)
- [业务场景SQL示例](business_scenarios.md)
- [datasource_guard 文档](../../datasource_guard/README.md)
- [data-diff 文档](../../data-diff/README.md)

## 📝 最佳实践

1. **Schema 管理**
   - 所有数据源必须有 Schema
   - Schema 变更必须走 PR
   - 保持向后兼容

2. **数据质量**
   - ETL 后立即检查
   - 设置合理阈值
   - 定期监控

3. **CI/CD**
   - 所有变更自动验证
   - 失败阻止合并
   - 保持流程自动化

## 🎯 下一步

1. 完善数据血缘追踪
2. 添加实时监控告警
3. 集成更多数据源
4. 优化性能
