# UI 高保真复刻总验收

设计来源：`docs/ui-reference/2026-07-11-chatgpt-design/` 目录中的 10 张参考图。

本轮按固定顺序逐页执行：量取结构 → 映射真实功能 → 重建展示层 → 模拟器截图 → 与参考图核对 → 第二轮微调 → 自动化验证。没有用演示数据替换数据库，也没有把旧页面仅做换色。

## 主页面验收结果

| 页面 | 结构重建 | 截图轮次 / 关键状态 | 结果 |
| --- | --- | --- | --- |
| 首页 | 品牌、问候、输入、快捷入口、整理结果、久坐、今日行动、AI 建议 | `home/round-1.png`、`round-2.png`、`final.png`、`today-task.png`、`empty.png` | 通过 |
| 任务 | 月/周切换、紧凑月历、当日时间线、任务筛选与操作 | `tasks/baseline.png`、`round-1.png`、`round-2.png`、`final.png` | 通过 |
| 复盘 | 日期仪表盘、四项真实指标、总结/鼓励/不足/建议、规划预览 | `review/baseline.png`、`round-1.png`、`final-summary.png`、`plan-state.png` | 通过 |
| 我的 | 登录页头、四列概览、快捷入口、六组设置 | `profile/baseline.png`、`round-1.png`、`final.png`、`lower-sections.png` | 通过 |

## 关键弹层验收结果

| 弹层 | 截图 | 结果 |
| --- | --- | --- |
| AI 整理确认 | 首页 extracted item 状态截图 | 通过；保留内联连续确认流程 |
| 任务编辑 | `modals/task-editor-final.png` | 通过 |
| 复盘补充 | `modals/review-note.png` | 通过 |
| 时间规划确认 | `modals/plan-confirm-sheet.png` | 通过 |
| 删除确认 | `modals/delete-confirm.png` | 通过 |

## 最终验收标准

- [x] 一次只复刻一个页面，首页通过后才进入任务、复盘和“我的”。
- [x] 每页均记录参考图结构、间距、字号层级和功能映射。
- [x] 旧版信息架构已替换，而不是只调整颜色和圆角。
- [x] 页面继续读取和修改真实 SQLite / Riverpod / API 数据。
- [x] 不存在的数据不伪造：专注时长、心情评分、活跃度等使用现有可靠指标映射或明确不展示。
- [x] 首页、任务、复盘、“我的”和关键弹层均有 iPhone 17 模拟器截图。
- [x] 每个主页面至少完成两轮视觉核对或覆盖空/有内容关键状态。
- [x] 截图使用的固定日期、固定 Tab、初始滚动位置和自动弹窗辅助代码已全部撤回。
- [x] App 默认从首页启动。
- [x] `git diff --check` 通过，无空白错误。
- [x] `flutter analyze` 通过，无静态检查问题。
- [x] `flutter test` 全量 171 项通过。

## 明确保留的产品差异

- 参考图包含大量演示任务和虚构指标；实现只展示模拟器真实数据。
- 当前产品没有可靠用户名来源，因此首页不硬编码参考图的 `Zgzdhr`。
- 当前没有专注时长、心情量表和记忆活跃度算法，不写入无法持久化的假字段。
- AI 整理确认继续采用首页内联卡片，便于连续确认多条解析结果。
- iPhone 17 动态岛与参考图设备模板不同，顶部安全区的绝对像素位置会自然不同。

## 验证命令

```bash
cd apps/mobile
flutter analyze
flutter test --reporter compact
```

最终结果：静态检查通过，Flutter 全量 171 项测试通过。
