# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are currently supported:

| Version | Supported          |
| ------- | ------------------ |
| 0.3     | :white_check_mark: |
| < 0.3   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **<durand.tibo+gh@gmail.com>**

Include the following information:

- Type of issue (e.g., injection vulnerability, unsafe handling of the `config` input, etc.)
- Full paths of affected source files
- Location of the affected code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### What to Expect

After submitting a vulnerability report:

1. **Acknowledgment**: You'll receive a response within 48 hours acknowledging your report
2. **Assessment**: We'll investigate and assess the vulnerability
3. **Timeline**: We'll keep you informed about our progress
4. **Resolution**: Once fixed, we'll coordinate disclosure timing with you
5. **Credit**: With your permission, we'll credit you in the security advisory

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
