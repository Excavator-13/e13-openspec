# e13-openspec

基于 [OpenSpec](https://github.com/Fission-AI/openspec)（[Fission-AI](https://github.com/Fission-AI) 开源的规范驱动开发框架）的个人定制版，提供实现交接、证据式验证、修复闭环和归档前验证检查，以及一个简化的 init 脚本。

## 与上游 OpenSpec 的关系

本项目的 skills 中，以下 2 个保持 OpenSpec 上游（[Fission-AI/openspec](https://github.com/Fission-AI/openspec)）原样，MIT 许可证：

| Skill                     | 用途                                                                |
| ------------------------- | ------------------------------------------------------------------- |
| `openspec-explore`        | 进入探索模式，以思考伙伴身份协助梳理需求和方案                      |
| `openspec-sync-specs`     | 将 change 中的 delta spec 合并到主 spec                             |

以下 4 个基于上游 skill 做必要适配，目录名和 skill 名都加上 `e13`，保留 MIT 许可证和上游来源信息：

| Skill                         | 适配内容 |
| ----------------------------- | -------- |
| `openspec-e13-propose`        | 规划流程保留，只将实现入口指向 e13 apply |
| `openspec-e13-apply-change`   | 按 tasks 实现，持久化实现笔记与验证提醒，完成后交给 e13 verify |
| `openspec-e13-update-change`  | 规划调整后重新打开需要实现的任务，衔接 e13 apply/verify/archive |
| `openspec-e13-archive-change` | 同步 spec 和归档前检查当前实现的独立验证 PASS |

上游还自带一个 `openspec-verify-change`（启发式检查，产出 CRITICAL / WARNING / SUGGESTION 三级建议）。本项目将其替换为以下 2 个 skill，同样以 MIT 许可证发布：

| Skill                        | 用途                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------- |
| `openspec-e13-verify-change` | 对已实现的 change 进行独立验证，产出基于证据的验证报告（verdict: PASS / FAIL / BLOCKED）    |
| `openspec-e13-fix-change`    | 根据验证报告中的 pending implementation findings 进行定向修复，修复后交回验证 workflow 确认 |

## 为什么替换上游的 verify

上游的 `openspec-verify-change` 是启发式检查——通过关键词搜索和合理推断给出建议，不产出正式裁决，也没有配套的修复流程。实际使用中，这种"软验证"难以真正守住归档前的质量门。

本项目用证据式验证 + 修复闭环替换它：

```
e13-propose → e13-apply → e13-verify → (e13-fix → e13-verify)* → e13-archive
```

- **e13-apply**：实现任务，在 change 目录中维护 `implementation-notes.md`，记录实现位置、技术决策、检查命令与结果、复现条件、易漏边界和阻塞项；完成、暂停和再次进入 `all_done` 时都提供交接
- **e13-verify**：只读检查实现与 spec 的一致性，逐项核实 apply 的提醒，运行测试/lint/type check 等可执行验证，产出持久化的 `verification.md` 报告（含 finding ID、分类、repair status 和验证输入快照），给出正式 verdict（PASS / FAIL / BLOCKED），不修改任何代码
- **e13-fix**：根据验证报告中 `category: implementation` 且 `repair status: pending` 的 findings 做最小化修复，修复后标记 `addressed-awaiting-verification`，交回 e13-verify 做独立确认
- **e13-archive**：归档前读取验证报告，要求当前 change 的 PASS、没有未解决 finding，且报告的规划和实现输入快照仍有效；通过后才进行原有的同步与归档流程

两者形成闭环：fix 不能自行声明验证通过，只有 verify 才能将 finding 标记为 `verified-resolved` 或给出最终 verdict。

apply 的笔记由 apply 维护，verify 只读；验证报告由 verify 维护，fix 只更新修复状态和修复笔记。笔记中的结果和提醒都是待独立核实的线索，不能覆盖 spec、降低验收要求或决定 verdict。旧 change 没有实现笔记也可验证；旧报告若缺少可比较的验证输入快照，需要重新验证后才能通过 e13 archive。

归档前的 PASS 检查由 skill 执行，不是 OpenSpec CLI 的强制校验；直接运行 CLI 归档命令不会执行这项检查。

## 目录结构

```
e13-openspec/              ← 本仓库
├── e13-openspec           ← init 脚本（bash，兼容 zsh）
├── e13-openspec.ps1       ← init 脚本（PowerShell，Windows 原生）
├── templates/
│   ├── .agents/
│   │   └── skills/
│   │       ├── .openspec-target
│   │       ├── openspec-e13-propose/SKILL.md        ← 适配
│   │       ├── openspec-e13-apply-change/SKILL.md   ← 适配
│   │       ├── openspec-e13-update-change/SKILL.md  ← 适配
│   │       ├── openspec-explore/SKILL.md
│   │       ├── openspec-sync-specs/SKILL.md
│   │       ├── openspec-e13-archive-change/SKILL.md ← 适配
│   │       ├── openspec-e13-verify-change/SKILL.md   ← 新增
│   │       └── openspec-e13-fix-change/SKILL.md       ← 新增
│   └── openspec/
│       ├── config.yaml
│       ├── specs/.gitkeep
│       └── changes/archive/.gitkeep
├── .gitignore
└── README.md
```

## 前置依赖

本项目的所有 skill 都依赖 [openspec CLI](https://www.npmjs.com/package/@fission-ai/openspec)（`@fission-ai/openspec`），需先安装：

```sh
npm install -g @fission-ai/openspec@latest
```

此外还需要一个支持 skill 的 AI 编程助手（如 Trae、Codex 等）来调用各 skill。

## 安装

### Linux / macOS（bash / zsh）

```sh
cp e13-openspec ~/bin/
chmod +x ~/bin/e13-openspec
cp -r templates/ ~/bin/templates
```

确保 `~/bin` 在 `PATH` 中：

**bash 用户：**

```sh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**zsh 用户：**

```sh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
exec zsh
```

### Windows（PowerShell）

```powershell
Copy-Item e13-openspec.ps1 $HOME\bin\
Copy-Item -Recurse templates $HOME\bin\templates
```

确保 `$HOME\bin` 在 `PATH` 中：

```powershell
# 将以下行加入 $PROFILE（若不存在可先运行 New-Item -Type File -Force $PROFILE）
$env:PATH = "$HOME\bin;$env:PATH"
```

## 使用

### macOS / Linux

在项目目录下运行：

```sh
cd /path/to/your-project
e13-openspec init        # 初始化 .agents/ 和 openspec/（已存在则跳过）
e13-openspec init -f     # 强制覆盖已存在的目录
e13-openspec update      # 更新 skill：删除旧的 openspec skill 后复制最新 skill
e13-openspec help        # 查看用法
```

### Windows（PowerShell）

```powershell
cd C:\path\to\your-project
.\e13-openspec.ps1 init        # 初始化 .agents/ 和 openspec/（已存在则跳过）
.\e13-openspec.ps1 init -f     # 强制覆盖已存在的目录
.\e13-openspec.ps1 update      # 更新 skill：删除旧的 openspec skill 后复制最新 skill
.\e13-openspec.ps1 help        # 查看用法
```

`init` 会将 `templates/` 下的 `.agents/` 和 `openspec/` 复制到当前目录。之后在 AI 编程助手中使用各 skill 即可。

已有项目的 `.agents/` 会被普通 `init` 跳过，不会自动获得此次 skill 更新。更新模板时，在目标项目里运行 `update` 即可：它会删除 `.agents/skills/` 下所有以 `openspec` 开头的旧 skill 目录（包括旧入口 `openspec-propose`、`openspec-apply-change`、`openspec-verify-change` 等），再把 `templates/.agents/skills/` 下的最新 skill 复制进去，因此不会残留指向原版流程的旧入口。`update` 只处理 skill 目录，不会改动 `openspec/` 下的 specs、changes 和 config，也不会动 `.agents/skills/` 里其他自定义 skill。

## 许可证

本项目以 MIT 许可证发布。其中来源于 [OpenSpec](https://github.com/Fission-AI/openspec) 的文件保留其原始 MIT 许可证声明。
