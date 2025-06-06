# DeepSeek 代码审查

![Tests](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgist.githubusercontent.com%2Fhustcer%2Fb99391ee59016b17d0befe3331387e89%2Fraw%2Ftest-summary.json&query=%24.total&label=Tests)
![Passed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgist.githubusercontent.com%2Fhustcer%2Fb99391ee59016b17d0befe3331387e89%2Fraw%2Ftest-summary.json&query=%24.passed&label=Passed&color=%2331c654)
![Failed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgist.githubusercontent.com%2Fhustcer%2Fb99391ee59016b17d0befe3331387e89%2Fraw%2Ftest-summary.json&query=%24.failed&label=Failed&color=red)
![Skipped](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fgist.githubusercontent.com%2Fhustcer%2Fb99391ee59016b17d0befe3331387e89%2Fraw%2Ftest-summary.json&query=%24.skipped&label=Skipped&color=yellow)

本工具也支持使用 SiliconCloud 上的 DeepSeek 模型，[注册](https://cloud.siliconflow.cn/i/rqCdIxzS) 就**免费赠送 2000 万 Token**，赶紧试试吧！

## 特性

### GitHub Action

- 通过 GitHub Action 使用 DeepSeek 进行自动化 PR 审查
- 在 PR 的标题或描述中添加 `skip cr` or `skip review` 可跳过 GitHub Actions 里的代码审查
- 跨平台：支持 GitHub `macOS`, `Ubuntu` & `Windows` Runners

### 本地代码审查

- 本地代码审查的时候支持流式输出
- 通过本地 CLI 直接审查远程 GitHub PR
- 通过本地 CLI 使用 DeepSeek 审查任何本地仓库的提交变更
- 允许通过自定义 `git show`/`git diff` 命令生成变更记录并进行审查
- 跨平台：理论上只要能运行 [Nushell](https://github.com/nushell/nushell) 即可使用本工具

### 本地或 GH Action

- 支持 DeepSeek `V3` 和 `R1` 模型
- 完全可定制：选择模型、基础 URL 和提示词
- 支持自托管 DeepSeek 模型，提供更强的灵活性
- 对指定文件变更进行包含/排除式代码审查

## 计划支持特性

- [ ] **通过提及触发代码审查**：当 PR 评论中提及 `github-actions bot` 时，自动触发代码审查
- [ ] **本地生成提交信息**：为本地仓库的代码变更生成 Commit Message

## 通过 GitHub Action 进行代码审查

### 创建 PR 时自动触发代码审查

创建一个 GitHub workflow 内容如下：

```yaml
name: Code Review
on:
  pull_request_target:
    types:
      - opened      # Triggers when a PR is opened
      - reopened    # Triggers when a PR is reopened
      - synchronize # Triggers when a commit is pushed to the PR

# fix: GraphQL: Resource not accessible by integration (addComment) error
permissions:
  pull-requests: write

jobs:
  setup-deepseek-review:
    runs-on: ubuntu-latest
    name: Code Review
    steps:
      - name: DeepSeek Code Review
        uses: hustcer/deepseek-review@v1
        with:
          chat-token: ${{ secrets.CHAT_TOKEN }}
```

<details>
  <summary>CHAT_TOKEN 配置</summary>

  按照以下步骤配置你的 `CHAT_TOKEN`：

  1. 点击仓库导航栏中的 "Settings" 选项卡
  2. 在左侧边栏中，点击 "Security" 下的 "Secrets and variables"
  3. 点击 "Actions" -> "New repository secret" 按钮
  4. 在 "Name" 字段中输入 `CHAT_TOKEN`
  5. 在 "Secret" 字段中输入你的 `CHAT_TOKEN` 值
  6. 最后，点击 "Add secret"按钮保存密钥

</details>

当 PR 创建的时候会自动触发 DeepSeek 代码审查，并将审查结果（依赖于提示词）以评论的方式发布到对应的 PR 上。比如：
- [示例 1](https://github.com/hustcer/deepseek-review/pull/30) 基于[默认提示词](https://github.com/hustcer/deepseek-review/blob/main/action.yaml#L35) & [运行日志](https://github.com/hustcer/deepseek-review/actions/runs/13043609677/job/36390331791#step:2:53).
- [示例 2](https://github.com/hustcer/deepseek-review/pull/68) 基于[这个提示词](https://github.com/hustcer/deepseek-review/blob/eba892d969049caff00b51a31e5c093aeeb536e3/.github/workflows/cr.yml#L32)

### 当 PR 添加指定 Label 时触发审查

如果你不希望创建 PR 时自动审查可以选择通过添加标签时触发代码审查，比如创建如下 Workflow：

```yaml
name: Code Review
on:
  pull_request_target:
    types:
      - labeled     # Triggers when a label is added to the PR

# fix: GraphQL: Resource not accessible by integration (addComment) error
permissions:
  pull-requests: write

jobs:
  setup-deepseek-review:
    runs-on: ubuntu-latest
    name: Code Review
    # Make sure the code review happens only when the PR has the label 'ai review'
    if: contains(github.event.pull_request.labels.*.name, 'ai review')
    steps:
      - name: DeepSeek Code Review
        uses: hustcer/deepseek-review@v1
        with:
          chat-token: ${{ secrets.CHAT_TOKEN }}
```

如此以来当 PR 创建的时候不会自动触发 DeepSeek 代码审查，只有你手工添加 `ai review` 标签的时候才会触发审查。

## 输入参数

| 名称           | 类型   | 描述                                                           |
| -------------- | ------ | -------------------------------------------------------------- |
| chat-token     | String | 必填，DeepSeek API Token                                       |
| model          | String | 可选，配置代码审查选用的模型，默认为 `deepseek-chat`           |
| base-url       | String | 可选，DeepSeek API Base URL, 默认为 `https://api.deepseek.com` |
| max-length     | Int    | 可选，待审查内容的最大 Unicode 长度, 默认 `0` 表示没有限制，超过非零值则跳过审查 |
| sys-prompt     | String | 可选，系统提示词对应入参中的 `$sys_prompt`, 默认值见后文注释      |
| user-prompt    | String | 可选，用户提示词对应入参中的 `$user_prompt`, 默认值见后文注释     |
| temperature    | Number | 可选，采样温度，介于 `0` 和 `2` 之间, 默认值 `1.0`        |
| include-patterns | String | 可选，代码审查中要包含的以逗号分隔的文件模式，无默认值 |
| exclude-patterns | String | 可选，代码审查中要排除的以逗号分隔的文件模式，默认值为 `pnpm-lock.yaml,package-lock.json,*.lock` |
| github-token   | String | 可选，用于访问 API 进行 PR 管理的 GitHub Token，默认为 `${{ github.token }}` |

DeepSeek 接口调用入参:

```js
{
  // `$model` default value: deepseek-chat
  model: $model,
  stream: false,
  temperature: $temperature,
  messages: [
    // `$sys_prompt` default value: You are a professional code review assistant responsible for
    // analyzing code changes in GitHub Pull Requests. Identify potential issues such as code
    // style violations, logical errors, security vulnerabilities, and provide improvement
    // suggestions. Clearly list the problems and recommendations in a concise manner.
    { role: 'system', content: $sys_prompt },
    // `$user_prompt` default value: Please review the following code changes
    // `diff_content` will be the code changes of current PR
    { role: 'user', content: $"($user_prompt):\n($diff_content)" }
  ]
}
```

> [!NOTE]
>
> 可以通过提示词的语言来控制代码审查结果的语言，当前默认的提示词语言是英文的，
> 当你使用中文提示词的时候生成的代码审查结果就是中文的

## 本地代码审查

### 依赖工具

在本地进行代码审查，支持 `macOS`, `Ubuntu` & `Windows` 不过需要安装以下工具：

- [`Nushell`](https://www.nushell.sh/book/installation.html), 建议安装最新版本
- [`awk`](https://github.com/onetrueawk/awk) 或者 [`gawk`](https://www.gnu.org/software/gawk/) 的最新版版本，优先推荐 `gawk`
- 接下来只需要把本仓库代码克隆到本地，然后进入仓库目录执行 `nu cr -h` 即可看到类似如下输出:

```console
Use DeepSeek AI to review code changes locally or in GitHub Actions

Usage:
  > nu cr {flags} (token)

Flags:
  -d, --debug: Debug mode
  -r, --repo <string>: GitHub repo name, e.g. hustcer/deepseek-review
  -n, --pr-number <string>: GitHub PR number
  -k, --gh-token <string>: Your GitHub token, fallback to GITHUB_TOKEN env var
  -t, --diff-to <string>: Diff to git REF
  -f, --diff-from <string>: Diff from git REF
  -c, --patch-cmd <string>: The `git show` or `git diff` command to get the diff content, for local CR only
  -l, --max-length <int>: Maximum length of the content for review, 0 means no limit.
  -m, --model <string>: Model name, or read from CHAT_MODEL env var, `deepseek-chat` by default
  -b, --base-url <string>: DeepSeek API base URL, fallback to BASE_URL env var
  -U, --chat-url <string>: DeepSeek Model chat full API URL, e.g. http://localhost:11535/api/chat
  -s, --sys-prompt <string>: Default to $DEFAULT_OPTIONS.SYS_PROMPT,
  -u, --user-prompt <string>: Default to $DEFAULT_OPTIONS.USER_PROMPT,
  -i, --include <string>: Comma separated file patterns to include in the code review
  -x, --exclude <string>: Comma separated file patterns to exclude in the code review
  -T, --temperature <float>: Temperature for the model, between `0` and `2`, default value `1.0`
  -C, --config <string>: Config file path, default to `config.yml`
  -h, --help: Display the help message for this command

Parameters:
  token <string>: Your DeepSeek API token, fallback to CHAT_TOKEN env var (optional)

```

### 环境配置

在本地进行代码审查需要先修改配置文件，仓库里已经有了 [`config.example.yml`](https://github.com/hustcer/deepseek-review/blob/main/config.example.yml) 配置文件示例，将其拷贝到 `config.yml` 然后根据自己的实际情况进行修改即可，在修改配置文件的过程中请仔细阅读其中的注释，注释会说明每个配置项的作用。

> [!WARNING]
>
> `config.yml` 配置文件仅在本地使用，在 GitHub Workflow 里面不会使用，里面的敏感信息请
> 妥善保存，不要提交到代码仓库里面
>

**创建命令别名**

为了方便您可以在任意本地仓库进行代码审查需要创建一个别名，比如：

```sh
# Nushell: 修改其 config.nu 配置文件，添加：
alias cr = nu /absolute/path/to/deepseek-review/cr --config /absolute/path/to/deepseek-review/config.yml

# Modify ~/.zshrc for zsh or ~/.bashrc for bash or ~/.config/fish/config.fish for fish and add:
alias cr="nu /absolute/path/to/deepseek-review/cr --config /absolute/path/to/deepseek-review/config.yml"
# After sourcing the profile you have edit, you can use `cr` now

# For Windows powershell users please set cr alias by editing $PROFILE and add:
function cr {
  nu D:\absolute\path\to\deepseek-review\cr --config D:\absolute\path\to\deepseek-review\config.yml @args
}

# Then restart the terminal or run `. $PROFILE` in pwsh to make `cr` work
```

之后就可以通过 `cr` 命令来进行代码审查了。

### 审查本地仓库

对本地仓库进行代码审查时需要先切换到 Git 仓库所在目录，然后通过 `cr` 命令即可对当前目录的当前修改进行代码审查，前提是您已经对 `config.yml` 进行了正确的配置。

**使用举例**

```sh
# 对本地当前目录所在仓库 `git diff` 修改内容进行代码审查
cr
# 对本地当前目录所在仓库 `git diff f536acc` 修改内容进行代码审查
cr --diff-from f536acc
# 对本地当前目录所在仓库 `git diff f536acc 0dd0eb5` 修改内容进行代码审查
cr --diff-from f536acc --diff-to 0dd0eb5
# 通过 --patch-cmd 参数对本地当前目录所在仓库变更内容进行审查
cr --patch-cmd 'git diff head~3'
cr -c 'git show head~3'
cr -c 'git diff 2393375 71f5a31'
cr -c 'git diff 2393375 71f5a31 nu/*'
cr -c 'git diff 2393375 71f5a31 :!nu/*'
# 像 `cr -c 'git show head~3; rm ./*'` 这样危险的命令将会被禁止
```

### 本地审查远程 GitHub PR

在本地对远程 GitHub 仓库的 PR 进行审查的时候一定要通过 `--pr-number` 传入待审查的 PR 编号，以及 `--repo` 指明待审查的仓库，比如 `hustcer/deepseek-review`, 如果没有指定 `--repo` 参数则从 config.yml 里面的 `settings.default-github-repo` 配置项读取待审查的仓库。

**使用举例**

```sh
# 对远程 DEFAULT_GITHUB_REPO 仓库编号为 31 的 PR 进行代码审查
cr --pr-number 31
# 对远程 hustcer/deepseek-review 仓库编号为 31 的 PR 进行代码审查
cr --pr-number 31 --repo hustcer/deepseek-review
# 对 PR 进行审查的时候排除 pnpm-lock.yaml 文件的变更
cr --pr-number 31 --exclude pnpm-lock.yaml
```

## 许可

Licensed under:

- MIT license ([LICENSE](LICENSE) or http://opensource.org/licenses/MIT)
