# 2026-07-10 安全与架构全面审计

状态：审计完成；第一轮私有试用整改进行中。
审计对象：当前 `main` 工作区（`HEAD fdd30f6`）及未提交的 Phase 5D.1 日历 / 重复任务 / 久坐改动。
结论：可以继续**私人、本地试用**；不应扩大分发或公开发布，直到 P0 项关闭。

## 1. 本次结论

项目的产品主线没有走偏：`/parse`、`/review`、`/plan` 已按职责拆开；AI 输出有 Zod schema 校验；长期画像、任务更新和时间规划均保留了用户确认边界；本地 SQLite 仍是运行时真相。

但当前版本不能作为公开产品发布，原因不是“代码太乱”，而是几个信任边界尚未闭环：公开 AI 代理会被滥用、Release 构建仍是测试姿态、云端上传不是可恢复同步、删除没有跨本地/云端的生命周期保证，且最新 5D.1 数据模型已超出当前云端合同。

```mermaid
flowchart LR
  A["手机输入 / 本地数据"] --> B["受控 API 网关\n身份、额度、限流"]
  B --> C["DeepSeek\n只接收最小必要上下文"]
  C --> D["结构 + 语义守门\n来源、任务 ID、日期范围"]
  D --> E["用户确认 / 明确自动保存策略"]
  E --> F["本地加固存储\n迁移、提醒、可删除"]
  F --> G["版本化备份/同步合同\nRLS、恢复、删除、注销"]
```

上图中 B、D、G 仍未完成；F 也需要补移动端隐私加固。

## 1A. 审计后的执行更新（2026-07-10）

本轮已经落地、但尚未完成真机/全量自动化验收的修复：

- `updateTaskById` 改为 Drift `Value` patch 语义；延期或改名不再因未传字段而清空任务描述、开始/结束时间。编辑任务会重新同步通知标题。
- `need_user_confirm=true` 成为移动端的硬门槛；parser prompt 也明确任务更新必须确认。
- `/parse`、`/review`、`/plan` 已增加登录 bearer token、Supabase Auth 验证、匿名拒绝、安全响应头、缩小 JSON 上限、每用户进程内突发限流和 Supabase 原子日额度。移动端仅在 AI 调用时附带当前 Supabase access token；每日额度 RPC 使用调用者 JWT，不使用 service-role key。
- Android 仅 Debug manifest 允许局域网 HTTP；Release 继承 Android 的禁止明文流量默认值。
- 手动云端上传已停止上传日历排期、重复任务、久坐会话；带有本地日程字段的任务也不会把精确时间通过旧的 cloud `due_time` 字段带出。

本轮继续补上：会话改为 Android KeyStore/iOS Keychain 存储，应用回到前台必须通过设备验证；iOS 本地数据库请求排除设备备份；云端副本增加显式、二次确认的删除路径；Supabase SQL 草案增加同一用户引用约束、`delete` 权限和匿名角色撤权。

尚未关闭的原因必须如实保留：最初整改后的 Flutter 基线和 API 全量测试已恢复绿色，但 secure storage、app lock、云端副本删除和原生配置加入后，Flutter 全量验证、真机试用、线上部署、真实 Supabase token/RLS 验证、Android/iOS 原生构建仍未完成。详见 `docs/architecture/private-trial-security-runbook-2026-07-10.md`。

## 2. 审计范围与证据边界

- 已检查 Flutter、API proxy、Drift schema/migration、Supabase SQL 草案、Android/iOS 配置、同步代码、测试、脚本、依赖清单和项目文档。
- 当前分支领先 `origin/main` 15 个提交，且有未提交的 5D.1 改动；本报告不把它们当作已经发布的版本，也没有重置、清理或修改这些内容。
- `git diff --check` 通过；Git 完整性检查退出成功，只发现未引用的 dangling objects，未做任何 prune/reset。
- 初次整改完成后，`flutter analyze` 与全量 `flutter test`（160 tests）通过；此证据早于 secure storage/app lock/cloud deletion 的最新移动端改动，必须重跑。`npm run typecheck` 与 `npm test` 已通过（79 tests）；`privacyLogging.test.ts` 的 listener teardown 已修复。
- `npm audit` 无法访问安全公告镜像，当前环境也无法获批重新联网检查；因此**不能**据此声称依赖无漏洞。
- 本轮没有连接真实 Supabase/Vercel 账号。RLS/环境变量/日志保留/部署 WAF 均为“源码草案已审、线上状态未验证”。

安全基线参考 [OWASP MASVS](https://mas.owasp.org/MASVS/) 的存储、认证、网络和隐私域，以及 [Supabase API 安全说明](https://supabase.com/docs/guides/api/securing-your-api) 的最小授权和 RLS 要求。下表的“问题”记录的是审计起点；以本节 1A 的整改状态和 `current-verification.md` 的最新证据为准。

## 3. 已确认的重点问题

| 优先级 | 问题 | 证据与影响 | 关闭标准 |
|---|---|---|---|
| P0 | AI API 是公开付费入口 | `apps/api/src/server.ts` 只有默认 `cors()` 和 1 MB body 限制；`/parse`、`/review`、`/plan` 无 token、限流、额度或并发保护，移动端也未传 `Authorization`。任何人可消耗 DeepSeek 额度。 | 除 `/health` 外一律验证用户身份；按用户 + IP 限流、日额度和并发保护；无 token 为 401/403，超额为 429。 |
| P0 | AI 任务更新会静默清空已有数据 | `AppDatabase.updateTaskById` 把可选 `description/startTime/endTime/dueTime` 直接写入；AI delay/edit 调用只传部分字段。一次延期可能清掉描述和开始/结束时间，编辑也可能留下旧提醒。 | 用明确的 patch 语义区分“未提供”与“明确清空”；补延期/编辑保留字段、提醒重排和回归测试。 |
| P0（启用云上传时） | 5D.1 本地模型与云端合同已脱节 | 本地 schema 已到 v6，新增任务 start/end、重复规则和久坐会话；`CloudSyncService` 与 Supabase SQL 均未覆盖。现有“云端同步完成”可能遗漏这些数据。 | 在完整覆盖前，将功能明确标为本地专属并在上传前告知；或补齐 schema、mapping、RLS、恢复和合同测试后再称为同步/备份。 |
| P0（公开发布前） | Android Release 仍是测试安全姿态 | 主 manifest 全局 `usesCleartextTraffic="true"`；release 使用 debug signing；Android/iOS 包名仍为 `com.example.mobile`。 | 分离 debug/release 网络配置；release 仅 HTTPS、唯一包名、正式签名和产物校验。 |
| P0（公开发布前） | 隐私、删除与注销未闭环 | 同步会上传 raw input 与 raw AI JSON；本地删除主要是停止参与建议/软删除，云端 SQL 没有 delete grant，未见云端删除、恢复、账号注销和保留期实现。 | 发布完整数据生命周期：上传提示、导出、云端删除、账号注销、session 失效、恢复与保留期；每项有端到端验收。 |
| P0 | 验证基线不是绿色 | 当前 9 个 Flutter 失败涵盖重复任务日期、久坐 UTC/本地时间以及日历改版后的 UI；API 隐私测试会挂起；`check-all.sh` 的 `set -e` 会掩盖后续 API 检查。 | 每条验证 lane 独立报告并设置超时；Flutter/API 全量测试均绿色、无挂起后才能恢复功能扩展。 |
| P1 | 手机上的敏感数据缺少显式加固策略 | SQLite 直接存于 Application Support；未见应用级加密、应用锁或备份排除规则。会话存储也未在项目代码中显式设定为 Keychain/Keystore 策略。 | 先确定“设备丢失/他人拿到已解锁手机”的威胁模型，再落实 app lock、备份控制、会话存储与数据库加密范围。 |
| P1 | AI 输出只有结构校验，没有语义守门 | `/review`、`/plan` 的 source/task ID 只校验非空字符串；客户端会保存模型返回的来源。未验证来源是否属于本次请求、时间块是否在当天窗口、task ID 是否存在。 | 在服务端建立输入集合白名单和日期/时间窗校验，客户端二次防御；模型伪造引用必须被拒绝。 |
| P1 | 自动保存没有读取 `need_user_confirm` | `ExtractedItemsController._shouldAutoSaveValues` 只看类型和本地规则；短期状态/近期任务可自动确认，即使模型要求确认。 | 把 `need_user_confirm` 变为真正硬门槛；若产品仍允许自动保存，prompt 必须明确返回 `false`，并用测试保证。 |
| P1 | RLS 草案合理，但缺少可重放、可验证的线上合同 | SQL 草案对每表启用 RLS 并以 `auth.uid() = user_id` 限制所有者，这是正确方向；但它位于文档目录，未形成版本化 migration，线上配置本轮未核验。 | 把 schema 迁入可审计 migration；增加用户 A/B 隔离、grant、Data API exposure 和 advisor 的 staging 测试。 |
| P1 | 时间与日程模型需要收紧 | 任务的 due/start/end 与 schedule block 都表达时间；重复实例在页面加载时生成，缺少数据库唯一约束与统一提醒重排。日期有 UTC/本地混用迹象。 | 明确任务时间是承诺/提醒、block 是计划草稿；使用本地日期键、唯一约束、停用/生成/提醒策略和时区测试。 |
| P2 | 可维护性、文档和自动化治理不足 | `AppDatabase`、任务/复盘/设置页面承担多类职责；无 CI、SAST、secret scan、依赖扫描、覆盖率门槛或固定工具链；README/验证记录落后于 5D.1。 | 只在新增能力时渐进拆分；建立独立 CI lanes、版本固定和一份可追踪的发布证据。 |

## 4. 下一步整改路线

### 阶段 0：冻结风险面（立即）

1. 不分发新的公开测试包；若生产 API 已有异常流量，先在 Vercel 侧临时限制访问或轮换 DeepSeek key，再实施正式鉴权。
2. 记录审计基线：`HEAD`、当前 dirty diff 哈希、Flutter/Node/npm 版本、各环境配置名（不记录密钥）。不对现有工作树执行 reset、clean 或 prune。
3. 在产品文案中临时准确表达：当前是“本机到云端的单向上传”，不是可恢复的完整同步；明确重复任务/久坐等未覆盖的数据范围，或暂时隐藏上传入口。

验收：当前测试包不再向外扩散；团队能说清“哪些数据会送给 AI、会上传云端、不会上传云端”。

### 阶段 1：先恢复数据正确性与可信验证

1. 修复任务更新 patch：默认保持未传字段，只有用户明确选择时才清空字段；任务变更后同步取消/重排本地通知。
2. 修复 5D.1 的重复实例边界、久坐 UTC/本地时间、日历 widget 测试，并决定如何处理 Drift 多 `AppDatabase` 警告。
3. 修复 API 隐私测试的 server close/fetch 生命周期；把 `scripts/check-all.sh` 改为 mobile、API、扫描、build 分别执行并汇总，即使其中一项失败也报告其余结果。
4. 新增 Drift 升级 fixture：至少验证 v1→v6、v4→v5、v5→v6 仍能保留用户任务、状态、复盘、计划与时间字段。

验收：`flutter analyze`、`flutter test`、`npm run typecheck`、`npm test` 均稳定退出 0；所有测试 lane 有硬超时和单独结果。

### 阶段 2：封住公开 AI 成本与滥用入口

1. 定义 provider-neutral `ApiAuth` 合同：移动端附带 access token，API middleware 解析为稳定的 `userId`；国际版先实现 Supabase JWT verifier，国内版以后替换 verifier，不把路由绑定到某个云厂商。
2. 保护 `/parse`、`/review`、`/plan`：身份验证、用户+IP 限流、日额度、并发上限、请求 ID/幂等键、统一超时；`/health` 仍可公开但不暴露敏感配置。
3. 收紧 CORS/安全响应头，限制各请求字段长度与集合大小；所有 provider 错误均规范化，不回显用户内容或内部细节。
4. 在 staging 做真实负向测试：无 token、过期 token、其他用户 token、超额、并发和取消请求。

验收：业务 AI 路由无法被匿名调用；预算、日志和异常请求均可追溯但不含用户正文。

### 阶段 3：定义数据生命周期与本地—云端合同

1. 先决定每类数据属于哪一种：仅本地、可上传备份、可恢复、可多端同步。对 5D.1 的重复规则、实例、久坐会话作出显式选择，不能默认遗漏。
2. 将 Supabase schema 变成版本化 migration；同步 mapping、RLS、grant、索引和恢复 contract 一起改，并增加 schema/mapping parity test。
3. 先实现“云端恢复到新设备”的单设备流程，再设计双向同步和冲突规则；恢复必须可预览、可重试、可去重。
4. 实现本地删除、云端删除、账号注销、导出和保留期。不要先加 delete 权限；只有删除流程和 RLS 负向测试准备好时才授予最小 delete 权限。

验收：测试用户 A 无法读取/修改/删除用户 B；本地上传→新设备恢复→本地删除/云端删除的全流程有证明；UI 不再把“上传成功”描述为“已同步”。

### 阶段 4：移动端发布与隐私加固

1. 建立 `debug`、国际 release、国内 release 的构建配置：仅 debug 允许本地 HTTP，release 强制 HTTPS 和受控 API 域名。
2. 配置正式 Android keystore、唯一 Android/iOS bundle ID、签名和发布产物检查；不把私钥、密码或 service-role key 放入仓库。
3. 根据威胁模型确定应用锁、设备备份控制、会话存储和 SQLite 加密。这里的核心目标是防止敏感日记/状态在设备丢失、备份或共享设备场景被意外暴露。
4. 重写隐私说明：分别列出 `/parse`、`/review`、`/plan`、云端上传的实际字段与用途；补正式隐私政策、注销与帮助入口。

验收：Release APK/AAB 和 iOS 真机分别通过 HTTPS、签名、通知、重启、弱网、时区、删除与隐私文案核对。

### 阶段 5：持续保障与渐进架构整理

1. 添加 CI：独立 mobile/API/security/build jobs，生成测试和扫描报告；锁定 Node/Flutter 工具链版本，保持 lockfile 更新策略。
2. 添加 secret/history scan、依赖漏洞 scan、SAST、SBOM/依赖清单和定期依赖更新；扫描失败不得被另一条 lane 掩盖。
3. 仅在真实新增能力时抽取 `TaskPatchService`、`CloudBackupRestoreService`、`Review/Schedule` repository 和偏好存储，不进行一次性“大重构”。
4. 统一 README、AGENTS、任务地图、验证记录和 release audit，使一个新 session 能从同一份现状开始。

## 4A. 下一阶段任务计划：私有试用验证与安全闭环

在扩展任何产品能力前，按以下顺序推进。每项完成后都应留下命令结果或真机记录。

1. 恢复验证基线：重新运行 `flutter analyze`、全量 `flutter test`、API 全量测试。先修复日历改版遗留的 widget 期望，再确认重复任务和久坐测试使用本地日历语义。为 API listener 测试保留可靠 teardown，并验证无 token=401、有效 token=200、限流=429。
2. 配置一个无真实私密数据的 staging：为 API 设置 `SUPABASE_URL` 和 publishable key；部署后用测试邮箱 OTP 做 `/parse`、`/review`、`/plan` 的登录前/后负向测试。未完成前不把认证代码部署为“已上线”。
3. 完成设备基础保护：安装并验证 secure session storage、应用锁和 Android/iOS 备份控制；先写清“解锁手机被他人拿到”场景下的保护承诺，再决定是否需要 SQLite 加密。
4. 做 AI 语义守门：对 `/review` 与 `/plan` 的 source id、task id、日期和时间窗口建立“只允许本次输入集合”的服务器校验，并增加模型伪造引用的测试。
5. 再处理云端数据生命周期：先实现可预览的单设备恢复和明确删除，再讨论自动同步或多端冲突。旧版本已上传的日历数据必须有可见的清理路径。
6. 最后才进入公开发布准备：正式包名、release signing、HTTPS-only 构建、永久额度、CI/security scan、隐私政策和账号注销。

## 5. 发布前必须完成的 live 审计

以下项目不能只靠读仓库确认，必须用**无敏感测试数据**在 staging/真实配置中复核：

- Supabase：全部表的 RLS、policy、grant、Data API exposure、Auth OTP 限流/redirect URL/JWT 时长/session 失效、跨用户负向测试。
- Vercel/API：环境变量权限、日志是否脱敏、WAF/限流、匿名请求拒绝、额度告警和 DeepSeek key 轮换流程。
- Android/iOS：最终产物的 manifest/ATS、签名证书、HTTPS、通知重启恢复、时区、设备丢失和备份行为。
- AI：提示注入、伪造 source/task ID、超长输入、模型超时/异常、重复提交和删除后上下文不再被带入。
- 供应链：在线 `npm audit`、Dart/Flutter 依赖检查、secret/history scan 与静态分析必须在可联网的 CI 或受控开发机复跑。

## 6. 给项目负责人的一句话判断

这不是需要推倒重来的项目。当前最值得做的不是继续加功能，而是先把“AI 不能被白嫖、数据不会静默丢、用户知道数据去哪、每次改动能被可靠验证”四件事做成硬门槛。完成阶段 1 和 2 后，再继续 5D.1 真机体验微调会更稳。
