# sign-app

`sign-app` is a bash script for macOS that simplifies the process of code signing user-installed applications. It provides a safe and user-friendly way to sign apps, excluding system applications to maintain system integrity.

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/sign-app.git
   ```

2. Navigate to the cloned directory:
   ```
   cd sign-app
   ```

3. Make the script executable:
   ```
   chmod +x sign-app
   ```

4. (Optional) Move the script to a directory in your PATH for system-wide access:
   ```
   sudo mv sign-app /usr/local/bin/
   ```

## Usage

### Basic Usage

To list all user-installed apps and select one to sign:

```
sign-app -l
```

To sign a specific app by name:

```
sign-app -n "App Name"
```

### Options

- `-n, --name <app_name>`: Sign a specific user-installed app by name
- `-l, --list`: List all user-installed macOS apps
- `-h, --help`: Display help information
- `-v, --verbose`: Enable verbose output
- `--update-list`: Force update of the cached app list
- `--check`: Verify if an app is already signed
- `--force`: Force re-signing even if the app is already signed
- `--entitlements <file>`: Specify custom entitlements file
- `--backup`: Create a backup of the app before signing

### Examples

1. List all user-installed apps and sign a selected one:
   ```
   sign-app -l
   ```

2. Sign a specific app named "MyApp":
   ```
   sign-app -n "MyApp"
   ```

3. Check if an app is signed:
   ```
   sign-app -n "MyApp" --check
   ```

4. Force re-sign an app with custom entitlements and create a backup:
   ```
   sign-app -n "MyApp" --force --entitlements /path/to/entitlements.plist --backup
   ```

5. Update the cached list of user-installed apps:
   ```
   sign-app --update-list
   ```

6. Sign an app with verbose output:
   ```
   sign-app -n "MyApp" -v
   ```

## Notes

- This script requires administrative privileges to sign apps. You may need to use `sudo` depending on your system configuration and the location of the apps you're trying to sign.
- The script creates a cache file at `$HOME/.sign_app_cache` to store the list of user-installed apps. You can force an update of this cache using the `--update-list` option.
- System apps (those in /System/Applications, signed by Apple, or with bundle IDs starting with com.apple.) are excluded from listing and signing operations to maintain system integrity.

## Troubleshooting

If you encounter any issues:

1. Ensure you have Xcode Command Line Tools installed.
2. Run the script with the `-v` or `--verbose` option for more detailed output.
3. Make sure you have the necessary permissions to sign the app.
4. If an app fails to sign, try using the `--force` option to override any existing signatures.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is provided as-is, without any warranty. Always ensure you have backups of your applications before signing them. Incorrect use of code signing can render applications unusable.
