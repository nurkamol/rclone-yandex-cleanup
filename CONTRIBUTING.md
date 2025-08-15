# Contributing to rclone-yandex-cleanup

First off, thank you for considering contributing to rclone-yandex-cleanup! It's people like you that make this tool better for everyone.

## Code of Conduct

By participating in this project, you are expected to uphold our simple code of conduct: be respectful and considerate to others.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Include your system details** (OS, bash version, rclone version)
- **Include relevant log outputs** (sanitize sensitive data)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. Make your changes and test thoroughly
3. Ensure your code follows the existing style
4. Test with DRY_RUN=true first
5. Update the README.md if needed
6. Issue the pull request

## Development Process

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/nurkamol/rclone-yandex-cleanup.git
cd rclone-yandex-cleanup

# Create a branch
git checkout -b feature/your-feature-name

# Make your changes
nano rclone-yandex-cleanup.sh

# Test with DRY RUN
./rclone-yandex-cleanup.sh
```

### Testing Checklist

Before submitting a PR, ensure:

- [ ] Script runs without syntax errors
- [ ] DRY_RUN mode works correctly
- [ ] File detection works properly
- [ ] Lock file mechanism functions
- [ ] No data loss in live mode
- [ ] Works with various directory structures

### Code Style

- Use 4 spaces for indentation (no tabs)
- Add comments for complex logic
- Keep functions focused and small
- Use meaningful variable names
- Follow existing naming conventions

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when relevant

Example:
```
Add bandwidth limiting option for rclone operations

- Add --bwlimit parameter to configuration
- Update README with new option
- Fixes #123
```

## Testing Guidelines

### Basic Test

```bash
# Test with sample directory structure
mkdir -p test-backup/site1.com
mkdir -p test-backup/site2.com
# Add some test .wpress files
# Run script in DRY_RUN mode
```

### Edge Cases to Test

- Empty directories
- Directories with no .wpress files
- Directories with exactly 10 files
- Directories with mixed file types
- Special characters in filenames

## Documentation

- Update README.md for new features
- Add inline comments for complex code
- Include examples for new options
- Update version number when appropriate

## Questions?

Feel free to open an issue with the label "question" if you need help or clarification.

## Recognition

Contributors will be recognized in the README.md file. Thank you for your contributions!

---

**Note**: By contributing to this project, you agree that your contributions will be licensed under the MIT License.