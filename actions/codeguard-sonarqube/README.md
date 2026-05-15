# CodeGuard SonarQube Action

Reusable GitHub Action that runs an ephemeral SonarQube analysis using dynamic CodeGuard rules.

This action:

- Starts a temporary SonarQube server
- Fetches the SonarQube rules configured for a CodeGuard team
- Runs the Sonar Scanner
- Extracts detected issues
- Generates analysis summaries
- Uploads the analysis results as workflow artifacts

---

## Features

- Ephemeral SonarQube setup
- Dynamic rules by team
- Multi-language support
- Automatic SonarQube profile configuration
- Sonar Scanner execution
- Issue extraction
- JSON and Markdown summaries
- Workflow artifacts
- Optional Quality Gate validation

---

## Prerequisites

Before using this action:

1. The CodeGuard GitHub App must be installed in the repository or organization.
2. You must have:
   - a valid `teamId`
   - a valid `installationId`
3. The installation and the team must belong to the same client.

---

## Configuring `sources`

By default, the action uses:

```txt
/usr/src
```
as the Sonar Scanner source path.

For standard repositories this is usually enough, but for monorepos or custom project structures you may need to explicitly configure the sources input.

Example monorepo structure:

```txt
apps/
packages/
libs/
```

Example configuration:

```yaml
- name: Run CodeGuard SonarQube Action
  uses: Fridaplatform/codeguard-extensions/actions/codeguard-sonarqube@master
  with:
    teamId: 'Vv3TLeju65pFCD2HnCLS'
    installationId: 'gh_132092397'
    projectKey: 'my-project'
    sources: 'apps,packages'
```
You can provide:

- a single directory
- multiple directories separated by commas
- custom source paths depending on your repository structure

Examples:
```yaml
sources: 'src'
```
```yaml
sources: 'apps/web,packages/shared'
```
```yaml
sources: 'services/api'
```

---

## Inputs

| Input | Required | Default | Description |
|---|---:|---|---|
| `teamId` | Yes | - | CodeGuard Team ID used to fetch the configured SonarQube rules. |
| `installationId` | Yes | - | GitHub App installation identifier associated with the repository or organization. |
| `projectKey` | Yes | - | SonarQube project identifier used for the analysis. |
| `rulesApiUrl` | No | `https://apis.codeguard.fridaplatform.online/Teams-getSonarRules` | CodeGuard API endpoint used to fetch SonarQube rules. |
| `sources` | Yes | `/usr/src` | Source path used by Sonar Scanner. |
| `exclusions` | No | `**/node_modules/**,**/dist/**,**/build/**,**/__pycache__/**` | Files and folders excluded from analysis. |
| `enforceQualityGate` | No | `true` | Fails the workflow if the SonarQube Quality Gate fails. |

---

## Minimal usage

```yaml
- name: Run CodeGuard SonarQube Action
  uses: Fridaplatform/codeguard-extensions/actions/codeguard-sonarqube@master
  with:
    teamId: 'Vv3TLeju65pFCD2HnCLS'
    installationId: 'gh_132092397'
    projectKey: 'test-project'
    rulesApiUrl: 'https://apis.codeguard-stg.fridaplatform.online/Teams-getSonarRules'
    sources: 'apps/web,packages/shared'
    exclusions: '**/node_modules/**,**/dist/**,**/build/**'
    newCodeReferenceBranch: ${{ github.base_ref || 'main' }}
```

---

## Full workflow example
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
        with:
          fetch-depth: 0

      - name: Run CodeGuard SonarQube Action
        uses: Fridaplatform/codeguard-extensions/actions/codeguard-sonarqube@master
        with:
          teamId: 'Vv3TLeju65pFCD2HnCLS'
          installationId: 'gh_132092397'
          projectKey: 'test-project'
          rulesApiUrl: 'https://apis.codeguard-stg.fridaplatform.online/Teams-getSonarRules'
          sources: 'apps/web,packages/shared'
          exclusions: '**/node_modules/**,**/dist/**,**/build/**'
          newCodeReferenceBranch: ${{ github.base_ref || 'main' }}
          
```
---