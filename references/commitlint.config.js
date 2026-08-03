// husky-skill · OPTIONAL commitlint config
// -----------------------------------------------------------------------------
// You do NOT need this. The `commit-msg` hook validates Conventional Commits in
// pure POSIX shell with zero dependencies.
//
// Use this file ONLY if your organization already standardizes on commitlint
// (e.g. in CI) and wants a config that mirrors the hook's rules exactly, so the
// local hook and the CI check never disagree.
//
//   npm i -D @commitlint/cli @commitlint/config-conventional
//   npx commitlint --edit "$1"
//
// Rules kept intentionally aligned with assets/hooks/commit-msg:
//   - types: feat fix docs style refactor perf test build ci chore revert
//   - scope: optional, lowercase/digits/dashes
//   - "!" marks a breaking change
//   - header (first line) ≤ 72 chars
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'],
    ],
    'scope-case': [2, 'always', 'kebab-case'],
    'subject-empty': [2, 'never'],
    'header-max-length': [2, 'always', 72],
  },
};
