# zsh-pinyin-completion-rs

中文拼音补全插件 for zsh，基于 [bash-pinyin-completion-rs](https://github.com/AOSC-Dev/bash-pinyin-completion-rs) 移植。

让中文用户在 zsh 中使用拼音快速补全中文文件名。例如，输入 `zg` 可以补全 `中国`，输入 `zj` 可以补全 `浙江`。

## 特性

- 支持全拼和多种双拼方案
- 自动检测拼音输入，不影响正常英文补全
- 无缝集成到 zsh 补全系统
- 可配置最小输入长度
- 支持路径补全（如 `cd /path/to/zg` 补全到 `中国` 目录）
- 遵循 [Zsh Plugin Standard](https://github.com/zdharma-continuum/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc)

## 安装

### 前置要求

- zsh 5.0+
- Rust (仅从源码编译时需要)

本插件遵循 [Zsh Plugin Standard](https://github.com/zdharma-continuum/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc)，支持任意插件管理器。

### Oh My Zsh

```bash
# 克隆到 Oh My Zsh 自定义插件目录
git clone https://github.com/WN90/zsh-pinyin-completion-rs ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-pinyin-completion-rs

# 进入目录并构建二进制
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-pinyin-completion-rs
./install.sh build
```

在 `~/.zshrc` 中添加插件：

```zsh
plugins=(... zsh-pinyin-completion-rs)
```

### Zinit

```zsh
zinit light WN90/zsh-pinyin-completion-rs
```

### Antigen

```zsh
antigen bundle WN90/zsh-pinyin-completion-rs
```

### 手动安装

```bash
git clone https://github.com/WN90/zsh-pinyin-completion-rs
cd zsh-pinyin-completion-rs
./install.sh build

# 在 ~/.zshrc 中添加
source /path/to/zsh-pinyin-completion-rs/zsh-pinyin-completion-rs.plugin.zsh
```

## 配置

通过环境变量配置插件，在加载插件前设置：

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `ZSH_PINYIN_NOTATION` | `quanpin` | 拼音方案 |
| `ZSH_PINYIN_MIN_LENGTH` | `1` | 最小输入长度 |
| `ZSH_PINYIN_ENABLED` | `1` | 是否启用 (0/1) |
| `ZSH_PINYIN_FILTER_BIN` | (自动) | 二进制文件路径 |

### 拼音方案

支持以下拼音方案（设置 `ZSH_PINYIN_NOTATION`）：

| 值 | 方案 | 示例 |
|----|------|------|
| `quanpin` | 全拼（默认） | `zhongguo` → `中国` |
| `xiaohe` | 小鹤双拼 | `vsgo` → `中国` |
| `ms` | 微软双拼 | `vsgo` → `中国` |
| `abc` | 智能 ABC | `vsgo` → `中国` |
| `jiajia` | 拼音加加 | - |
| `thunisoft` | 紫光拼音 | - |
| `zrm` | 自然码 | - |

#### 全拼模式包含简拼

`quanpin` 模式自动包含简拼（首字母）匹配：

| 输入 | 匹配 | 说明 |
|------|------|------|
| `zg` | `中国` | 首字母 `z` + `g` |
| `zs` | `浙江`、`证书` | 首字母 `z` + `s` |
| `z` | `浙江`、`桌面`、`自己` | 所有 `z` 开头的字 |
| `zhongguo` | `中国` | 完整拼音 |
| `zguo` | `中国` | 首字母 + 完整拼音 |

可以组合多个方案：

```zsh
export ZSH_PINYIN_NOTATION="quanpin,xiaohe"
```

### 示例配置

```zsh
# 使用小鹤双拼
export ZSH_PINYIN_NOTATION="xiaohe"

# 最少输入 2 个字符才触发拼音补全
export ZSH_PINYIN_MIN_LENGTH=2

# 然后加载插件
source /path/to/zsh-pinyin-completion-rs/zsh-pinyin-completion-rs.plugin.zsh
```

## 使用方法

加载插件后，在 zsh 中：

1. 输入拼音首字母或完整拼音
2. 按 Tab 触发补全
3. 匹配的中文文件名会出现在补全列表中

### 示例

假设目录下有文件：`浙江.txt`、`江苏.txt`、`北京.txt`、`中国/`

```bash
$ cat zj<Tab>      # 补全为: 浙江.txt
$ cd zg<Tab>       # 补全为: 中国/
$ ls js<Tab>       # 补全为: 江苏.txt
```

### 命令行工具

插件提供两个辅助命令：

- `zsh-pinyin-toggle` - 切换拼音补全开关
- `zsh-pinyin-status` - 显示当前配置状态

## 工作原理

1. 插件注册 `_zsh_pinyin_complete` 到 zsh 的 completer 链
2. 当用户按 Tab 时，检查输入是否为纯小写字母
3. 如果是，调用 Rust 二进制过滤当前目录的中文文件名
4. 返回匹配的结果给 zsh 补全系统

## 已知限制

### 双拼单字母匹配范围

在双拼模式下，单字母输入会映射到对应的声母首字母进行匹配：

| 双拼方案 | 输入 | 映射 | 匹配范围 |
|---------|------|------|----------|
| 小鹤 | `v` | `z` | 所有 `z` 或 `zh` 开头的字 |
| 小鹤 | `u` | `s` | 所有 `s` 或 `sh` 开头的字 |
| 小鹤 | `i` | `c` | 所有 `c` 或 `ch` 开头的字 |

**示例：** 在小鹤双拼模式下，输入 `v` 会同时匹配 `桌面` (zhuo) 和 `自己` (zi)，因为它们都以 `z` 开头。

**原因：** 底层的拼音匹配库 (`ib_matcher`) 的 `AsciiFirstLetter` 模式只支持单字母首字母匹配，无法区分 `z` 和 `zh` 等多字母声母。

**解决方案：** 如需精确匹配，请使用完整的双拼编码：
- `vo` → 匹配 `zhuo` (桌)
- `zi` → 匹配 `zi` (自)

### 菜单补全行为

当中英文混合匹配时（如输入 `s` 同时匹配 `snap` 和 `视频`）：
- 第一次按 Tab 显示匹配列表，命令行保持原输入
- 继续按 Tab 在列表中循环选择

## 从源码构建

```bash
git clone https://github.com/WN90/zsh-pinyin-completion-rs
cd zsh-pinyin-completion-rs
cargo build --release
```

编译后的二进制位于 `target/release/zsh-pinyin-filter`，可复制到 `bin/` 目录。

## 与原项目的区别

| 特性 | bash-pinyin-completion-rs | zsh-pinyin-completion-rs |
|------|---------------------------|--------------------------|
| Shell | bash | zsh |
| 环境变量 | `PINYIN_COMP_MODE` | `ZSH_PINYIN_NOTATION`（兼容原变量） |
| 集成方式 | bash-complete | zstyle completer |

## 致谢

- [AOSC-Dev/bash-pinyin-completion-rs](https://github.com/AOSC-Dev/bash-pinyin-completion-rs) - 原始 bash 版本
- [IbPinyinLib](https://github.com/Chaoses-Ib/IbPinyinLib) - 拼音匹配库
- [petronny/pinyin-completion](https://github.com/petronny/pinyin-completion) - Zsh Plugin Standard 参考

## 许可证

GPL-3.0 License - 详见 [LICENSE](LICENSE) 文件
