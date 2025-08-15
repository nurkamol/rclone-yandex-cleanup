# rclone-yandex-cleanup

Automated backup rotation and cleanup tool for Yandex Disk using rclone. Specifically designed for managing WordPress backup files from All-in-One WP Migration plugin (.wpress files).

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/nurkamol/rclone-yandex-cleanup/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![rclone](https://img.shields.io/badge/rclone-required-orange.svg)](https://rclone.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/nurkamol/rclone-yandex-cleanup/pulls)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/nurkamol/rclone-yandex-cleanup/graphs/commit-activity)

## 🎯 Purpose

This script helps maintain a clean and organized backup storage by:
- Automatically removing old WordPress backup files
- Keeping only the most recent N backups per website
- Preventing storage overflow on Yandex Disk
- Supporting multiple WordPress sites in a single backup directory

## ✨ Features

- **Smart Retention Policy**: Keeps only the last 10 backups (configurable) for each website
- **Multi-Site Support**: Manages backups for multiple WordPress sites automatically
- **Safe Operation**: Includes DRY RUN mode for testing before actual deletion
- **File Locking**: Prevents multiple instances from running simultaneously
- **Selective Cleanup**: Only targets `.wpress` files, preserving other file types
- **Detailed Logging**: Comprehensive output with color-coded status messages
- **Cron-Ready**: Designed for automated scheduling via crontab

## 📋 Prerequisites

- **Linux/Unix System** (Tested on Debian 12)
- **Bash** 5.0 or higher
- **rclone** configured with Yandex Disk remote
- **Python3** (optional, for enhanced size reporting)
- Active Yandex Disk account with configured rclone remote

## 🚀 Installation

1. **Clone the repository**:
```bash
git clone https://github.com/nurkamol/rclone-yandex-cleanup.git
cd rclone-yandex-cleanup
```

2. **Make the script executable**:
```bash
chmod +x rclone-yandex-cleanup.sh
```

3. **Configure rclone** (if not already done):
```bash
rclone config
# Follow prompts to add Yandex Disk remote
```

## ⚙️ Configuration

Edit the script to match your setup:

```bash
# Configuration section at the top of the script
REMOTE_NAME="yandex-disk"          # Your rclone remote name
REMOTE_PATH="Backups"               # Remote folder path on Yandex Disk
LOCAL_BACKUP_PATH="/home/user/backup/"  # Local backup directory
KEEP_FILES=10                       # Number of backups to keep per site
TARGET_EXTENSION="wpress"           # File extension to manage
DRY_RUN=true                       # Set to false for actual deletion
```

## 📁 Expected Directory Structure

```
Yandex Disk:
└── Backups/
    ├── example.com/
    │   ├── example-com-20250814-163551-xxxxx.wpress
    │   ├── example-com-20250807-163521-xxxxx.wpress
    │   └── ...
    ├── another-site.com/
    │   ├── another-site-com-20250814-xxxxxx.wpress
    │   └── ...
    └── ...
```

## 🎮 Usage

### Manual Execution

**Test with DRY RUN mode** (default):
```bash
./rclone-yandex-cleanup.sh
```

**Execute actual cleanup**:
```bash
# Edit script and set DRY_RUN=false, then run:
./rclone-yandex-cleanup.sh
```

### Automated Execution (Cron)

Add to crontab for automated cleanup:

```bash
# Edit crontab
crontab -e

# Run weekly on Sundays at 2 AM
0 2 * * 0 /path/to/rclone-yandex-cleanup.sh >> /var/log/rclone-yandex-cleanup.log 2>&1

# Or run daily at 3 AM
0 3 * * * /path/to/rclone-yandex-cleanup.sh >> /var/log/rclone-yandex-cleanup.log 2>&1
```

## 📊 Script Workflow

1. **Lock Acquisition**: Prevents multiple instances from running
2. **Backup Upload**: Syncs local backups to Yandex Disk
3. **Directory Scanning**: Identifies all website folders
4. **File Analysis**: For each website:
   - Lists all `.wpress` files
   - Sorts by modification time (newest first)
   - Identifies files to keep and delete
5. **Cleanup Execution**: Removes old backups (if not in DRY RUN mode)
6. **Summary Report**: Displays statistics and disk usage
7. **Lock Release**: Allows future runs

## 🔒 Safety Features

- **DRY RUN Mode**: Test what would be deleted without actual removal
- **File Type Protection**: Only processes `.wpress` files
- **Lock File**: Prevents concurrent execution
- **Atomic Operations**: Each file deletion is independent
- **Verification**: Double-checks file extensions before deletion

## 📝 Log Management

### Basic Logging
```bash
# Redirect output to log file
./rclone-yandex-cleanup.sh >> /var/log/rclone-yandex-cleanup.log 2>&1
```

### Log Rotation Setup
Create `/etc/logrotate.d/rclone-yandex-cleanup`:
```
/var/log/rclone-yandex-cleanup.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0644 root root
}
```

## 🔍 Example Output

```
rclone-yandex-cleanup v1.0.0
Yandex Disk Backup Management System
================================================
🔍 DRY RUN MODE - No files will be deleted
Target: .wpress files only

Processing: example.com
  Found 15 .wpress file(s)
  Will delete 5 old .wpress backup(s)...
  Keeping these files:
    ✓ example-com-20250814-backup.wpress
    ✓ example-com-20250807-backup.wpress
    ... (8 more recent files)
  Files to delete:
    × example-com-20250501-backup.wpress ... [DRY RUN - Would DELETE]
    × example-com-20250424-backup.wpress ... [DRY RUN - Would DELETE]
    ... (3 more old files)

Summary: 934 files, 698.41 GB total
```

## ⚡ Performance Optimization

### Bandwidth Limiting
To limit bandwidth usage, add to rclone commands:
```bash
rclone copy ... --bwlimit 10M  # Limit to 10 MB/s
```

### Low Priority Execution
Run with nice for lower system priority:
```bash
nice -n 10 ./rclone-yandex-cleanup.sh
```

## 🐛 Troubleshooting

### Common Issues

1. **"Another instance is already running"**
   - Check for stuck lock file: `rm /var/lock/rclone-yandex-cleanup.lock`

2. **"directory not found" errors**
   - Verify rclone remote configuration: `rclone lsd yandex-disk:`
   - Check remote path exists: `rclone lsd yandex-disk:Backups`

3. **No files being processed**
   - Verify file extension setting matches your backup files
   - Check directory structure on Yandex Disk

4. **Permission denied**
   - Ensure script has execute permissions: `chmod +x rclone-yandex-cleanup.sh`
   - Check write permissions for log directory

## 📋 System Requirements

- **OS**: Linux/Unix (Tested on Debian 12)
- **Shell**: Bash 5.0+
- **Dependencies**: 
  - rclone (required)
  - python3 (optional, for size calculations)
  - Standard Unix utilities: awk, sed, sort, head, tail, wc

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Test thoroughly with DRY RUN mode
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

### Guidelines

- Ensure the script passes DRY RUN mode tests
- Update README.md with details of changes if applicable
- Follow the existing code style
- Add comments for complex logic
- Test with multiple WordPress sites if possible

## ⚠️ Important Notes

- Always test with `DRY_RUN=true` before actual deletion
- The script uploads new backups before cleaning old ones
- Deleted files cannot be recovered from Yandex Disk trash
- Keep logs for audit trail of deleted backups
- Monitor disk usage regularly to adjust retention policy

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Community & Support

- **Issues**: [Report bugs or request features](https://github.com/nurkamol/rclone-yandex-cleanup/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/nurkamol/rclone-yandex-cleanup/discussions)
- **Wiki**: [Additional documentation and tips](https://github.com/nurkamol/rclone-yandex-cleanup/wiki)

## ⭐ Show Your Support

If this project helped you, please consider giving it a star on GitHub! It helps others discover the tool.

## 👤 Author

**Your Name**

- GitHub: [@nurkamol](https://github.com/nurkamol)
- Email: [nurkamol@gmail.com](mailto:nurkamol@gmail.com)

## 🙏 Acknowledgments

- Developed for managing All-in-One WP Migration plugin backups
- Uses [rclone](https://rclone.org/) for Yandex Disk integration
- Tested in production environment with 50+ WordPress sites
- Inspired by the need for automated backup management

## 📈 Project Status

- ✅ Production ready
- ✅ Actively maintained
- ✅ Open for contributions

---

**Latest Release**: v1.0.0 (August 2025)  
**Downloads**: See [Releases](https://github.com/nurkamol/rclone-yandex-cleanup/releases)  
**Star History**: [![Star History Chart](https://api.star-history.com/svg?repos=nurkamol/rclone-yandex-cleanup&type=Date)](https://star-history.com/#nurkamol/rclone-yandex-cleanup&Date)
