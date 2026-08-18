# MoonBVHKit 项目申报书

## 基本信息

- 项目名称：MoonBVHKit：MoonBit 原生 BVH 动作捕捉解析、校验与资产管线工具
- 参赛者：张博文
- 联系方式：15614198610
- GitHub 账号：`zhangbowen2006`
- GitHub 仓库：<https://github.com/zhangbowen2006/MoonBVHKit>
- Mooncakes：`zhangbowen2006/moonbvhkit@0.2.0`
- 项目方向：游戏与动画资产管线基础库 / 开发工具
- 是否为移植项目：否，原创项目；开源许可证：MIT

## 项目简介

MoonBVHKit 是一个用 MoonBit 实现的 ASCII BVH 动作捕捉处理库。它解析骨骼层级、通道和动作帧，在资产进入 Unity、Blender、Godot 或自研运行时之前完成结构校验、运动分析、质量评分和导入门禁，并输出可供 CI、编辑器桥接脚本和数据看板使用的 Text、JSON、CSV 与 JUnit XML 报告。

## 项目方向与适用场景

项目补充了 MoonBit 生态中的动画资产处理能力，适用于游戏资产入库检查、动作捕捉数据预处理、骨架兼容性核对、root motion 分析、动作重采样、批量质量门禁和引擎导入前验证。核心库不依赖图形界面或编辑器 SDK，可在普通 MoonBit 工程和 GitHub Actions 中运行。

## 已实现的核心功能

- 解析 `ROOT`、嵌套 `JOINT`、`End Site`、`OFFSET`、`CHANNELS`、`MOTION`、帧数、帧时间和固定宽度帧数据；
- 查询关节路径、通道顺序、帧值、root position、通道范围、静态通道、动作时长和 root motion 空间边界；
- 校验未知通道、非 root 位移、通道偏移、帧数、帧宽和帧时间，返回带源码位置和稳定错误码的诊断；
- 提供骨架摘要与签名、骨架差异、同名骨骼 retarget map、动作切片、保持时长的最近邻重采样、root speed、teleport 检测和原点归一化；
- 提供 0 至 100 的质量评分，以及 Unity、Blender、Strict CI、Preview 四类策略和多资产批量门禁；
- 提供 Unity clip plan、Blender import plan、可运行 CLI、basic example、中英文 README、API 与架构文档；
- 配置 GitHub Actions CI 和 Windows 一键验收脚本，90 个测试全部通过，约 4,600 行有效 MoonBit 源码。

## 原创与参考说明

本项目为张博文原创的 MoonBit 实现，不是移植项目。实现依据公开通用的 BVH 文本结构独立设计，没有复制其他开源项目代码。仓库只依赖 MoonBit core，不包含私有代码、商业代码、下载的动作文件或第三方素材；所有 BVH fixture 均为手写合成数据，来源与生成文件说明见 `docs/PROVENANCE.md`。

## 完成与验收状态

版本 `0.2.0` 已发布至 Mooncakes。`moon check --deny-warn`、`moon build`、`moon test --deny-warn`、`moon fmt --check`、`moon info`、14 步验收脚本、CLI 各输出模式和 `examples/basic` 全部通过。仓库保留 7 个真实有效提交、CI 配置、测试记录、更新日志、架构说明和明确功能边界。项目专注 ASCII BVH 解析、分析和资产门禁，不包含编辑器插件、二进制 BVH、IK、旋转烘焙、完整动作重定向、坐标系转换及 FBX、glTF、USD 处理。
