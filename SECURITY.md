# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are currently supported:

| Version | Supported          |
| ------- | ------------------ |
| 0.3     | :white_check_mark: |
| < 0.3   | :x:                |

## Reporting a Vulnerability

The `workflow-config-action` team takes security bugs seriously. We appreciate your efforts to
responsibly disclose your findings.

### Where to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities privately using
[GitHub Security Advisories](https://github.com/durandtibo/workflow-config-action/security/advisories/new).

### What to Expect

- We will acknowledge receipt of your report within **5 business days**.
- We will provide an initial assessment (including whether the report is accepted, and an
  estimated timeline for a fix) within **10 business days** of acknowledgment.

### What to Include

Please include the following information in your report:

- Type of issue (e.g., injection vulnerability, unsafe handling of the `config` input, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.

### Security Update Policy

- Security updates will be released as soon as possible
- Security updates will be clearly marked in release notes
- We will notify users through GitHub releases and other appropriate channels

## Security Best Practices

When using this action:

1. **Pin Action Versions**: Use a specific version tag (or a commit SHA) instead of `@main`

   ```yaml
   # Good
   uses: durandtibo/workflow-config-action@v0.3.0

   # Avoid
   uses: durandtibo/workflow-config-action@main
   ```

2. **Minimal Permissions**: The action only reads files, so `contents: read` is enough

   ```yaml
   permissions:
     contents: read
   ```

3. **Trusted Config Files**: Only point the `config` input to files you control. Do not use a
   config file coming from an untrusted pull request.

## Known Limitations

- The action does not validate the values in the config file, it only checks that the file exists
  and that the requested keys are present
- The outputs are strings that consumers may use in `runs-on` or `matrix`, so a malicious config
  file could select an unexpected runner

## Dependencies

This action uses:

- Standard Unix utilities (`bash`, `jq`) - pre-installed on GitHub Actions runners

We rely on GitHub-hosted runners' maintained environment and do not bundle external dependencies.
