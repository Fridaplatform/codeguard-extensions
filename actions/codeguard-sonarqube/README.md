# CodeGuard SonarQube Action

Reusable GitHub Action for ephemeral SonarQube analysis using dynamic CodeGuard rules.

---

# Features

- Dynamic rules by `teamId`
- Multi-language support
- Ephemeral SonarQube setup
- Sonar Scanner execution
- Issue extraction
- Summary artifact generation
- Quality Gate validation

---

# Inputs

| Input | Required | Description |
|---|---|---|
| `teamId` | Yes | CodeGuard Team ID |
| `projectKey` | Yes | SonarQube project key |
| `rulesApiUrl` | No | CodeGuard rules API URL |
| `sources` | No | Sonar source path |
| `exclusions` | No | Sonar exclusions |
| `enforceQualityGate` | No | Fails workflow if Quality Gate fails |

---

# Usage

```yaml
- uses: Fridaplatform/codeguard-extensions/actions/codeguard-sonarqube@master
  with:
    teamId: Vv3TLeju65pFCD2HnCLS
    projectKey: my-project
```

---

# Workflow Example

```yaml
name: CodeGuard Sonar Analysis

on:
  pull_request:
    branches: [ master ]

jobs:
  sonar-analysis:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run CodeGuard SonarQube Action
        uses: Fridaplatform/codeguard-extensions/actions/codeguard-sonarqube@master
        with:
          teamId: Vv3TLeju65pFCD2HnCLS
          projectKey: test-project
```

---

# Artifacts

The action uploads a workflow artifact named:

```txt
sonar-analysis-results
```

Artifact contents:

```txt
sonar-results/
├─ issues.json
├─ summary.json
└─ summary.md
```