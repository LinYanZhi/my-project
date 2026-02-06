# 环境管理工具使用说明

## 简介

本工具提供了两种环境管理方式：
- **重置环境**：完全覆盖当前环境，仅保留核心系统变量
- **添加环境**：在现有环境基础上添加自定义配置

## 脚本文件

- `my.cmd` - 主入口脚本
- `reset-env.cmd` - 重置环境脚本
- `add-env.cmd` - 添加环境脚本

## 使用方法

### 列出可用环境
```bash
my list
```

### 重置环境
```bash
my reset <环境名>
```

### 添加环境
```bash
my add <环境名>
```

## 变量管理详情

### 1. my.cmd（主入口脚本）

#### 临时变量
- `CURRENT_ENV`：从PROMPT中提取的当前环境名称
  - **作用**：用于标识当前激活的环境
  - **生命周期**：仅在`my list`命令执行期间存在，执行完毕后销毁

#### 影响范围
- 无直接修改外部环境变量的操作
- 仅调用其他脚本或显示信息

### 2. reset-env.cmd（重置环境脚本）

#### 临时变量（前缀：_MY_）
- `_MY_TEMP`：保存原始TEMP变量
- `_MY_TMP`：保存原始TMP变量
- `_MY_USERPROFILE`：保存原始USERPROFILE变量
- `_MY_USERNAME`：保存原始USERNAME变量
- `_MY_SystemRoot`：保存原始SystemRoot变量
- `_MY_ComSpec`：保存原始ComSpec变量
- `_MY_SystemDrive`：保存原始SystemDrive变量
- `_MY_PATH`：保存原始PATH变量
- `_MY_ENV`：保存原始MY_ENV变量

#### 保留的外部变量
- `TEMP`：系统临时目录
- `TMP`：系统临时目录
- `USERPROFILE`：用户配置文件目录
- `USERNAME`：当前用户名
- `SystemRoot`：Windows系统目录
- `ComSpec`：命令解释器路径
- `SystemDrive`：系统驱动器
- `PATH`：系统路径（仅保留原始值，后续会被新配置覆盖）

#### 修改的外部变量
- `PROMPT`：命令提示符，格式为`[环境名] $P$G`
- `MY_ENV`：当前环境名称
- `PATH`：系统路径，由系统默认路径 + 用户自定义路径组成
- 从`variable.ini`加载的所有变量

#### 销毁的变量
- 除保留变量外的所有其他环境变量
- 所有`_MY_`前缀的临时变量

### 3. add-env.cmd（添加环境脚本）

#### 临时变量
- `USER_PATHS`：构建新的PATH变量
- `APPEND_PATH`：用于路径追加的临时变量

#### 持久化临时变量
- `_OLD_MY2_VIRTUAL_PROMPT`：保存原始PROMPT变量
- `_OLD_MY2_VIRTUAL_PATH`：保存原始PATH变量
  - **作用**：用于在停用环境时恢复原始配置
  - **生命周期**：从激活环境开始，到停用环境时销毁

#### 保留的外部变量
- 所有原始环境变量（不清除任何变量）

#### 修改的外部变量
- `PROMPT`：命令提示符，格式为`[环境名] 原始提示符`
- `PATH`：系统路径，由用户自定义路径 + 原始PATH组成
- 从`variable.ini`加载的所有变量（会覆盖同名原始变量）

#### 销毁的变量
- `USER_PATHS`：构建PATH的临时变量
- `APPEND_PATH`：路径追加的临时变量
- 当执行停用操作时，会销毁`_OLD_MY2_VIRTUAL_PROMPT`和`_OLD_MY2_VIRTUAL_PATH`

## 环境配置文件

### variable.ini

格式：`变量名=变量值`

示例：
```ini
# Python环境配置
PYTHON_HOME=C:\Python39
PYTHONPATH=C:\Python39\Lib;C:\Python39\DLLs

# 其他自定义变量
MY_PROJECT_HOME=C:\Projects
```

### path.ini

格式：每行一个路径

示例：
```ini
# 自定义工具路径
C:\Tools\bin
C:\Scripts

# 项目路径
C:\Projects\my-project\bin
```

## 注意事项

1. **reset-env** 会完全覆盖当前环境，仅保留核心系统变量，适合需要干净环境的场景

2. **add-env** 会在现有环境基础上添加配置，适合需要保持现有环境的场景

3. **变量优先级**：
   - reset-env：配置文件中的变量 > 系统保留变量
   - add-env：配置文件中的变量 > 原始环境变量

4. **路径优先级**：
   - reset-env：系统默认路径 > 用户自定义路径
   - add-env：用户自定义路径 > 原始PATH路径

5. **停用环境**：
   - reset-env：执行 `my reset` 或 `reset-env.cmd` 无参数时，会重置为默认命令提示符
   - add-env：执行 `my add` 或 `add-env.cmd` 无参数时，会恢复原始环境配置

## 示例

### 列出环境
```bash
my list
```

### 激活开发环境（重置方式）
```bash
my reset dev
```

### 激活测试环境（添加方式）
```bash
my add test
```

### 停用环境
```bash
my reset
# 或
my add
```
