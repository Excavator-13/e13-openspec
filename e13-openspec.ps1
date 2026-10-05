#
# e13-openspec — 初始化 .agents/ 和 openspec/
#
# 用法:
#   cd C:\path\to\project
#   .\e13-openspec.ps1 init          # 已存在的目录会跳过
#   .\e13-openspec.ps1 init -f       # 已存在的目录会先删除再复制
#   .\e13-openspec.ps1 update        # 删除旧的 openspec skill 并复制最新 skill

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir = Join-Path $scriptDir "templates"

function Usage {
    Write-Output "用法: e13-openspec <命令>"
    Write-Output ""
    Write-Output "命令:"
    Write-Output "  init [-f]   将 .agents/ 和 openspec/ 复制到当前目录"
    Write-Output "  update      删除 .agents/skills/ 下原有的 openspec skill，并复制最新 skill"
}

$command = if ($args.Length -gt 0) { $args[0] } else { "" }

switch ($command) {
    "init" {
        $force = $false
        if ($args.Length -gt 1 -and ($args[1] -eq "-f" -or $args[1] -eq "--force")) {
            $force = $true
        }

        foreach ($d in @(".agents", "openspec")) {
            $srcPath = Join-Path $srcDir $d
            $destPath = Join-Path $PWD.Path $d

            if (-not (Test-Path $srcPath -PathType Container)) {
                Write-Error "错误: 模板目录不存在: $srcPath"
                exit 1
            }

            if (Test-Path $destPath) {
                if ($force) {
                    Write-Warning "删除已存在的 $d ..."
                    Remove-Item -Recurse -Force $destPath
                } else {
                    Write-Warning "跳过 $d（已存在，加 -f 可覆盖）"
                    continue
                }
            }

            Copy-Item -Recurse -Force $srcPath $destPath
            Write-Output "✓ 已复制 $d"
        }
    }

    "update" {
        $srcSkills = Join-Path (Join-Path $srcDir ".agents") "skills"
        $destSkills = Join-Path (Join-Path $PWD.Path ".agents") "skills"

        if (-not (Test-Path $srcSkills -PathType Container)) {
            Write-Error "错误: 模板目录不存在: $srcSkills"
            exit 1
        }

        if (-not (Test-Path $destSkills)) {
            New-Item -ItemType Directory -Force -Path $destSkills | Out-Null
        }

        Get-ChildItem -Path $destSkills -Directory | Where-Object { $_.Name -like "openspec*" } | ForEach-Object {
            Remove-Item -Recurse -Force $_.FullName
            Write-Output "✓ 已删除旧 skill: $($_.Name)"
        }

        Get-ChildItem -Path $srcSkills -Directory | Where-Object { $_.Name -like "openspec*" } | ForEach-Object {
            Copy-Item -Recurse -Force $_.FullName (Join-Path $destSkills $_.Name)
            Write-Output "✓ 已复制 skill: $($_.Name)"
        }

        $markerSrc = Join-Path $srcSkills ".openspec-target"
        $markerDest = Join-Path $destSkills ".openspec-target"
        if ((Test-Path $markerSrc -PathType Leaf) -and -not (Test-Path $markerDest)) {
            Copy-Item -Force $markerSrc $markerDest
            Write-Output "✓ 已复制 .openspec-target"
        }
    }

    { $_ -in @("", "help", "-h", "--help") } {
        Usage
    }

    default {
        Write-Error "未知命令: $command"
        Usage
        exit 1
    }
}