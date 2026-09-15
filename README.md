# e13-openspec

基于 [OpenSpec](https://github.com/Fission-AI/openspec)（[Fission-AI](https://github.com/Fission-AI) 开源的规范驱动开发框架）的个人定制版，用更强的证据式验证 + 修复闭环替换了上游的启发式验证 skill，并提供一个简化的 init 脚本。

## 与上游 OpenSpec 的关系

本项目的 skills 中，以下 6 个直接来源于 OpenSpec 上游（[Fission-AI/openspec](https://github.com/Fission-AI/openspec)），MIT 许可证：

| Skill                     | 用途                                                                |
| ------------------------- | ------------------------------------------------------------------- |
| `openspec-propose`        | 一键生成 change 的全部规划产物（proposal / specs / design / tasks） |
| `openspec-apply-change`   | 按 tasks.md 逐步实现代码                                            |
| `openspec-update-change`  | 修改已有规划产物并保持一致性                                        |
| `openspec-explore`        | 进入探索模式，以思考伙伴身份协助梳理需求和方案                      |
| `openspec-sync-specs`     | 将 change 中的 delta spec 合并到主 spec                             |
| `openspec-archive-change` | 归档已完成的 change                                                 |

上游还自带一个 `openspec-verify-change`（启发式检查，产出 CRITICAL / WARNING / SUGGESTION 三级建议）。本项目将其替换为以下 2 个 skill，同样以 MIT 许可证发布：

| Skill                        | 用途                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------- |
| `openspec-e13-verify-change` | 对已实现的 change 进行独立验证，产出基于证据的验证报告（verdict: PASS / FAIL / BLOCKED）    |
| `openspec-e13-fix-change`    | 根据验证报告中的 pending implementation findings 进行定向修复，修复后交回验证 workflow 确认 |

## 为什么替换上游的 verify

上游的 `openspec-verify-change` 是启发式检查——通过关键词搜索和合理推断给出建议，不产出正式裁决，也没有配套的修复流程。实际使用中，这种"软验证"难以真正守住归档前的质量门。

本项目用证据式验证 + 修复闭环替换它：

```
propose → apply → e13-verify → (e13-fix → e13-verify)* → archive
```

- **e13-verify**：只读检查实现与 spec 的一致性，运行测试/lint/type check 等可执行验证，产出持久化的 `verification.md` 报告（含 finding ID、分类、repair status），给出正式 verdict（PASS / FAIL / BLOCKED），不修改任何代码
- **e13-fix**：根据验证报告中 `category: implementation` 且 `repair status: pending` 的 findings 做最小化修复，修复后标记 `addressed-awaiting-verification`，交回 e13-verify 做独立确认

两者形成闭环：fix 不能自行声明验证通过，只有 verify 才能将 finding 标记为 `verified-resolved` 或给出最终 verdict。

## 目录结构

```
e13-openspec/              ← 本仓库
├── e13-openspec           ← init 脚本（bash，兼容 zsh）
├── e13-openspec.ps1       ← init 脚本（PowerShell，Windows 原生）
├── templates/
│   ├── .agents/
│   │   └── skills/
│   │       ├── .openspec-target
│   │       ├── openspec-propose/SKILL.md
│   │       ├── openspec-apply-change/SKILL.md
│   │       ├── openspec-update-change/SKILL.md
│   │       ├── openspec-explore/SKILL.md
│   │       ├── openspec-sync-specs/SKILL.md
│   │       ├── openspec-archive-change/SKILL.md
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
openspec update
```

此外还需要一个支持 skill 的 AI 编程助手（如 Trae、Codex 等）来调用各 skill。

## 安装

### macOS / Linux（bash / zsh）

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

> **提示：** Windows 用户也可以通过 [Git Bash](https://git-scm.com/) 使用 bash 版脚本，安装方式与 macOS / Linux 相同。

## 使用

### macOS / Linux

在项目目录下运行：

```sh
cd /path/to/your-project
e13-openspec init        # 初始化 .agents/ 和 openspec/（已存在则跳过）
e13-openspec init -f     # 强制覆盖已存在的目录
e13-openspec help        # 查看用法
```

### Windows（PowerShell）

```powershell
cd C:\path\to\your-project
.\e13-openspec.ps1 init        # 初始化 .agents/ 和 openspec/（已存在则跳过）
.\e13-openspec.ps1 init -f     # 强制覆盖已存在的目录
.\e13-openspec.ps1 help        # 查看用法
```

`init` 会将 `templates/` 下的 `.agents/` 和 `openspec/` 复制到当前目录。之后在 AI 编程助手中使用各 skill 即可。

## 许可证

本项目以 MIT 许可证发布。其中来源于 [OpenSpec](https://github.com/Fission-AI/openspec) 的文件保留其原始 MIT 许可证声明。
