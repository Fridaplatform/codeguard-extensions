# CodeGuard Sonar Action

GitHub Action to run SonarQube with dynamic CodeGuard rules.

## Usage

```yaml
steps:
  - uses: CodeGuard/codeguard-sonar-action@main
    with:
      teamId: 'softtek'
      projectKey: 'frida'