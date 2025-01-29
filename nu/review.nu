#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/01/29 13:02:15
# TODO:
#   [√] Deepseek code reivew for Github PRs
#   [√] Deepseek code reivew for local commit changes
# Description: A script to do code review by deepseek
# Env vars:
#  GITHUB_TOKEN: Your Github API token
#  DEEPSEEK_TOKEN: Your Deepseek API token
# Usage:
#

const DEFAULT_OPTIONS = {
  MODEL: 'deepseek-chat',
  BASE_URL: 'https://api.deepseek.com',
  USER_PROMPT: '请分析以下代码变更：',
  SYS_PROMPT: '你是一个专业的代码审查助手，负责分析GitHub Pull Request的代码变更，指出潜在的问题，如代码风格、逻辑错误、安全漏洞，并提供改进建议。请用简洁明了的语言列出问题及建议。',
}

export def deepseek-review [
  token?: string,     # Your Deepseek API token, fallback to DEEPSEEK_TOKEN
  --diff: string,     # Diff content, e.g. `git diff` output
  --repo: string,     # Github repository name, e.g. hustcer/deepseek-review
  --pr-number: int,   # Github PR number
  --gh-token: string, # Your Github token, GITHUB_TOKEN by default
  --model: string = $DEFAULT_OPTIONS.MODEL,   # Model name, deepseek-chat by default
  --base-url: string = $DEFAULT_OPTIONS.BASE_URL,
  --sys-prompt: string = $DEFAULT_OPTIONS.SYS_PROMPT,
  --user-prompt: string = $DEFAULT_OPTIONS.USER_PROMPT,
] {

  let token = $token | default $env.DEEPSEEK_TOKEN?
  if ($token | is-empty) {
    print 'Please provide your Deepseek API token by setting DEEPSEEK_TOKEN or passing it as an argument.'
    return
  }
  $env.GITHUB_TOKEN = $gh_token | default $env.GITHUB_TOKEN?
  let diff_content = if ($diff | is-empty) {
      gh pr diff $pr_number --repo $repo | str trim
    } else { $diff }
  let payload = {
    model: $model,
    stream: 'false',
    messages: [
      { role: 'system', content: $sys_prompt },
      { role: 'user', content: $"($user_prompt):\n($diff_content)" }
    ]
  }
  print $'🚀 Start code review for PR #($pr_number) in ($repo) by Deepseek AI ...'; hr-line
  let header = [Authorization $'Bearer ($token)']
  let url = $'($base_url)/chat/completions'
  let response = http post -H $header -t application/json $url $payload
  let review = $response | get choices.0.message.content
  if ($response | get status) != 200 {
    print $'❌ Code review failed！Error: ($response | get content)'
    return
  }
  gh pr comment $pr_number --body $review --repo $repo
  print $'✅ Code review finished！PR #($pr_number) review result was posted as a comment.'
}

# If current host is Windows
export def windows? [] {
  # Windows / Darwin / Linux
  (sys host | get name) == 'Windows'
}

# Check if some command available in current shell
export def is-installed [ app: string ] {
  (which $app | length) > 0
}

export def hr-line [
  width?: int = 90,
  --color(-c): string = 'g',
  --blank-line(-b),
  --with-arrow(-a),
] {
  # Create a line by repeating the unit with specified times
  def build-line [
    times: int,
    unit: string = '-',
  ] {
    0..<$times | reduce -f '' { |i, acc| $unit + $acc }
  }

  print $'(ansi $color)(build-line $width)(if $with_arrow {'>'})(ansi reset)'
  if $blank_line { char nl }
}

alias main = deepseek-review
