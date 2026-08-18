# MoonBVHKit

[English](README.md)

MoonBVHKit 是一个 MoonBit 原生的 ASCII BVH 动作捕捉解析、校验、分析与资产门禁工具库。它可以在动作文件进入 Unity、Blender、Godot 或自研运行时之前，检查骨架层级、通道、帧数据、root motion 和导入质量，并输出适合自动化流程使用的 Text、JSON 与 CSV 报告。

## 发布状态

- GitHub：<https://github.com/zhangbowen2006/MoonBVHKit>
- Mooncakes：[`zhangbowen2006/moonbvhkit@0.1.0`](https://mooncakes.io/docs/zhangbowen2006/moonbvhkit@0.1.0)
- 许可证：MIT
- 维护者：张博文（GitHub：`zhangbowen2006`）
- 验证结果：72 个测试全部通过，严格检查、构建、格式检查、API 快照、CLI 和示例均通过

## 已实现能力

- 解析 `ROOT`、嵌套 `JOINT`、`End Site`、`OFFSET`、`CHANNELS` 和 `MOTION`；
- 查询关节名称、路径、通道顺序、单关节帧值、root position 和 root motion；
- 校验未知通道、通道偏移、帧数、帧宽、帧时间和非 root 位移通道；
- 统计动作时长、通道范围、静态通道、root speed 和 root teleport；
- 生成骨架摘要、稳定签名、骨架差异和同名骨骼 retarget map；
- 对动作进行切片、按时间取帧和 root 原点归一化；
- 生成 0 到 100 的导入质量评分和自动化处理建议；
- 提供 Unity、Blender、Strict CI、Preview 四类资产门禁策略；
- 输出 Text、JSON、CSV、Unity clip plan 和 Blender import plan；
- 提供可运行 CLI、basic example、72 个测试和 GitHub Actions CI。

## 安装

```bash
moon add zhangbowen2006/moonbvhkit@0.1.0
```

## 本地运行

在仓库根目录执行：

```bash
moon check --deny-warn
moon build
moon test --deny-warn
moon run cmd/main
moon run cmd/main -- --quality --json
moon run cmd/main -- --profiles --csv
moon run examples/basic
```

Windows 可以运行完整验收脚本：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1
```

## 最小用法

```mbt
test "parse a BVH clip" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  let document = parsed.document
  let validation = @moonbvhkit.validate_document(document)
  let quality = @moonbvhkit.quality_report(document)
  assert_true(validation.ok())
  assert_eq(quality.score, 100)
}
```

## 功能边界

当前版本专注于可移植的 ASCII BVH 库和资产门禁，不包含 Unity Editor 插件、Blender Python 插件、二进制或私有 BVH 变体、IK、旋转烘焙、完整动作重定向、坐标系转换以及 FBX、glTF、USD 处理。CLI 使用内置合成 fixture 保持 CI 确定性；实际文件内容由宿主程序读取后传给 `parse_bvh`。

## 文档与合规

- [API 文档](docs/API.md)
- [架构设计](docs/ARCHITECTURE.md)
- [集成指南](docs/INTEGRATION.md)
- [测试与验收记录](docs/TESTING.md)
- [来源与许可证说明](docs/PROVENANCE.md)
- [最终验收报告](submission/ACCEPTANCE_REPORT.md)

本项目为张博文原创的 MoonBit 实现，不是移植项目。仓库不包含复制的第三方代码、下载的动作资产或商业素材；测试 BVH 全部为手写合成数据。作者与维护信息见 [AUTHORS.md](AUTHORS.md)。
