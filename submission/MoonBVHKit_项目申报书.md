# MoonBVHKit 项目申报书

## 基本信息

- 项目名称：MoonBVHKit：MoonBit 原生 BVH 动作捕捉解析、校验与资产管线工具
- 参赛者：张博文；GitHub：`zhangbowen2006`；联系方式：15614198610
- GitHub 仓库：<https://github.com/zhangbowen2006/MoonBVHKit>
- Mooncakes：`zhangbowen2006/moonbvhkit@0.1.0`（已发布）
- 项目方向：游戏与动画资产管线基础库 / 开发工具
- 项目性质：原创项目；许可证：MIT

## 项目简介

MoonBVHKit 是一个用 MoonBit 实现的 ASCII BVH 动作捕捉处理库。它解析骨骼层级、通道和动作帧，在动作文件进入 Unity、Blender、Godot 或自研运行时之前完成结构校验、运动分析、质量评分和资产门禁，并输出可供 CI、编辑器桥接脚本和数据看板使用的 Text、JSON 与 CSV 报告。

## 项目方向与适用场景

项目补充了 MoonBit 生态中的动画资产处理能力，适用于游戏资产入库检查、动作捕捉数据预处理、骨架兼容性核对、root motion 分析、批量质量门禁和引擎导入前验证。核心库不依赖图形界面或编辑器 SDK，可以在普通 MoonBit 工程和 GitHub Actions 中稳定运行。

## 已实现的核心功能

- 解析 `ROOT`、嵌套 `JOINT`、`End Site`、`OFFSET`、`CHANNELS`、`MOTION`、帧数、帧时间和固定宽度帧数据；
- 提供关节路径、通道顺序、帧值、root position、root motion、通道范围、静态通道和动作时长查询；
- 校验未知通道、非 root 位移通道、通道偏移、帧数、帧宽和帧时间，并返回带位置与稳定错误码的诊断；
- 提供骨架摘要与签名、骨架差异、同名骨骼 retarget map、动作切片、按时间取帧、root speed、teleport 检测和原点归一化；
- 提供 0 至 100 的质量评分，以及 Unity、Blender、Strict CI、Preview 四类导入策略与自动化决策；
- 提供 Text、JSON、CSV、Unity clip plan、Blender import plan、CLI 和 basic example；
- 提供中英文 README、API、架构、集成、测试、来源、发布、安全文档和 GitHub Actions CI。

## 工程与验收状态

项目已发布至 Mooncakes。最终验证中，`moon check --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt --check`、`moon info`、CLI 各输出模式和 `examples/basic` 全部通过；测试共 72 个，覆盖解析、错误路径、查询、校验、分析、骨架、动作工具、质量评分、导入策略、导出和端到端资产门禁。仓库约有 4,100 行有效 MoonBit 源码，并保留 6 个真实开发提交、CI 记录、测试记录、更新日志和架构说明。

## 原创、参考与开源合规

本项目为原创 MoonBit 实现，不是移植项目。实现仅依据公开通用的 BVH 文本结构设计，没有复制其他项目代码；仓库只依赖 MoonBit core，不包含私有代码、商业代码、下载的动作文件或其他第三方素材。所有测试 fixture 均为手写合成数据。根目录采用 MIT License，详细来源说明见 `docs/PROVENANCE.md`。

## 功能边界

版本 0.1.0 专注 ASCII BVH 解析、校验、分析和资产门禁，不包含 Unity Editor 或 Blender Python 插件、二进制或私有 BVH、IK、旋转烘焙、完整动作重定向、坐标系转换以及 FBX、glTF、USD 处理。CLI 使用内置合成 fixture 保持 CI 确定性；宿主程序读取实际 BVH 文本后通过 `parse_bvh` 接入核心库。
