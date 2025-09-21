# Shell Starter - Migration Guide

This document provides guidance for migrating between different versions of Shell Starter. It covers breaking changes, migration steps, and compatibility information.

## 🔄 General Migration Principles

When updating Shell Starter dependencies in your project:

1. **Always backup your work** before updating
2. **Review the changelog** for your target version
3. **Test in development first** before updating production
4. **Update incrementally** rather than skipping major versions
5. **Use the built-in update tool** for safer migrations

```bash
# Recommended migration workflow
./bin/update-shell-starter --dry-run    # Preview changes
./bin/update-shell-starter --check      # Check for updates
./bin/update-shell-starter              # Apply with safety checks
```

## 📋 Version Migration Matrix

| From Version | To Version | Breaking Changes | Migration Required |
|--------------|------------|------------------|-------------------|
| 0.1.x        | 0.2.x      | ⚠️ Function names | Manual updates needed |
| 0.2.x        | 0.3.x      | ⚠️ Color variables | Manual updates needed |
| 0.3.x        | 0.4.x      | ⚠️ Spinner API | Manual updates needed |
| 0.4.x        | 1.0.x      | ⚠️ Major restructure | Full migration required |

## 🚨 Breaking Changes by Version

### Version 0.2.0 - Function Namespace Changes

**Release Date:** TBD
**Impact:** 🔴 High - All logging function calls need updates

#### What Changed

Logging functions moved from underscore to namespace syntax for consistency:

```bash
# ❌ Old syntax (0.1.x)
log_info "Starting process"
log_warn "Configuration missing"
log_error "Process failed"
log_debug "Debug information"

# ✅ New syntax (0.2.x+)
log::info "Starting process"
log::warn "Configuration missing"
log::error "Process failed"
log::debug "Debug information"
```

#### Migration Steps

1. **Update function calls** in all your scripts:
   ```bash
   # Use find and replace in your scripts
   sed -i.bak 's/log_info/log::info/g' bin/* lib/*.sh
   sed -i.bak 's/log_warn/log::warn/g' bin/* lib/*.sh
   sed -i.bak 's/log_error/log::error/g' bin/* lib/*.sh
   sed -i.bak 's/log_debug/log::debug/g' bin/* lib/*.sh
   ```

2. **Test all scripts** to ensure they work correctly:
   ```bash
   # Test each script individually
   ./bin/your-script --help
   ./bin/your-script --version
   ```

3. **Update documentation** and examples that reference the old function names

#### Compatibility Notes

- **Backward compatibility:** None - old function names will cause errors
- **Forward compatibility:** New syntax will work in all future versions
- **Detection:** The update tool will warn about this breaking change

### Version 0.3.0 - Color Variable Standardization

**Release Date:** TBD
**Impact:** 🟡 Medium - Color variable references need updates

#### What Changed

All color variables now use a consistent `COLOR_` prefix:

```bash
# ❌ Old syntax (0.2.x and earlier)
echo "${RED}Error message${RESET}"
echo "${BOLD}${BLUE}Header text${RESET}"
echo "${GREEN}Success${RESET}"

# ✅ New syntax (0.3.x+)
echo "${COLOR_RED}Error message${COLOR_RESET}"
echo "${COLOR_BOLD}${COLOR_BLUE}Header text${COLOR_RESET}"
echo "${COLOR_GREEN}Success${COLOR_RESET}"
```

#### Complete Variable Mapping

| Old Variable | New Variable |
|--------------|--------------|
| `BLACK` | `COLOR_BLACK` |
| `RED` | `COLOR_RED` |
| `GREEN` | `COLOR_GREEN` |
| `YELLOW` | `COLOR_YELLOW` |
| `BLUE` | `COLOR_BLUE` |
| `PURPLE` | `COLOR_PURPLE` |
| `CYAN` | `COLOR_CYAN` |
| `WHITE` | `COLOR_WHITE` |
| `BOLD` | `COLOR_BOLD` |
| `DIM` | `COLOR_DIM` |
| `UNDERLINE` | `COLOR_UNDERLINE` |
| `RESET` | `COLOR_RESET` |

#### Migration Steps

1. **Update color variable references**:
   ```bash
   # Automated replacement script
   for file in bin/* lib/*.sh; do
       [[ -f "$file" ]] || continue
       sed -i.bak \
           -e 's/\${BLACK}/\${COLOR_BLACK}/g' \
           -e 's/\${RED}/\${COLOR_RED}/g' \
           -e 's/\${GREEN}/\${COLOR_GREEN}/g' \
           -e 's/\${YELLOW}/\${COLOR_YELLOW}/g' \
           -e 's/\${BLUE}/\${COLOR_BLUE}/g' \
           -e 's/\${PURPLE}/\${COLOR_PURPLE}/g' \
           -e 's/\${CYAN}/\${COLOR_CYAN}/g' \
           -e 's/\${WHITE}/\${COLOR_WHITE}/g' \
           -e 's/\${BOLD}/\${COLOR_BOLD}/g' \
           -e 's/\${DIM}/\${COLOR_DIM}/g' \
           -e 's/\${UNDERLINE}/\${COLOR_UNDERLINE}/g' \
           -e 's/\${RESET}/\${COLOR_RESET}/g' \
           "$file"
   done
   ```

2. **Verify changes** by checking color output:
   ```bash
   ./bin/show-colors  # Should display correctly
   ```

3. **Clean up backup files** once migration is verified:
   ```bash
   find . -name "*.bak" -delete
   ```

#### Compatibility Notes

- **Backward compatibility:** None - old variable names will be undefined
- **Impact:** Scripts using color variables directly will show no colors or errors
- **Recommended:** Use logging functions which handle colors automatically

### Version 0.4.0 - Spinner API Changes

**Release Date:** TBD
**Impact:** 🟡 Medium - Spinner function calls need updates

#### What Changed

Spinner functions moved to namespace syntax and improved API:

```bash
# ❌ Old syntax (0.3.x and earlier)
start_spinner "Loading data"
stop_spinner

# ✅ New syntax (0.4.x+)
spinner::start "Loading data"
spinner::stop
```

#### Migration Steps

1. **Update spinner function calls**:
   ```bash
   sed -i.bak 's/start_spinner/spinner::start/g' bin/* lib/*.sh
   sed -i.bak 's/stop_spinner/spinner::stop/g' bin/* lib/*.sh
   ```

2. **Test spinner functionality**:
   ```bash
   ./bin/long-task  # Should show spinners correctly
   ```

#### Compatibility Notes

- **Backward compatibility:** None - old function names will cause errors
- **New features:** Enhanced spinner with better terminal compatibility
- **Performance:** Improved spinner rendering performance

### Version 1.0.0 - Major API Restructure

**Release Date:** TBD
**Impact:** 🔴 Very High - Complete migration required

#### What Changed

Version 1.0.0 represents a major architectural update:

- **Library reorganization:** Functions moved between files
- **New configuration system:** Centralized configuration management
- **Enhanced error handling:** Consistent error codes and messages
- **Improved documentation:** Comprehensive API documentation
- **Breaking changes:** Multiple API changes for consistency

#### Migration Path

Due to the extensive nature of 1.0.0 changes, migration requires careful planning:

1. **Assessment phase:**
   - Inventory all Shell Starter function usage in your project
   - Identify custom extensions and modifications
   - Plan testing strategy for updated code

2. **Preparation phase:**
   - Create comprehensive backups
   - Set up development environment for testing
   - Review 1.0.0 documentation and examples

3. **Migration phase:**
   - Update Shell Starter libraries
   - Follow specific migration guides for each breaking change
   - Test thoroughly in development environment

4. **Validation phase:**
   - Run full test suite
   - Verify all functionality works as expected
   - Update documentation and examples

#### Detailed Migration Guide

A detailed migration guide for 1.0.0 will be provided closer to release, including:
- Automated migration scripts
- Step-by-step instructions
- Troubleshooting guides
- Compatibility matrices

## 🛠️ Migration Tools

### Using update-shell-starter

The built-in update tool provides safety features for migrations:

```bash
# Check what version you're currently on
cat .shell-starter-version

# Check for available updates
./bin/update-shell-starter --check

# Preview what would change
./bin/update-shell-starter --dry-run

# Apply updates with breaking change warnings
./bin/update-shell-starter

# Update to specific version
./bin/update-shell-starter --target-version 0.2.0

# Force update (bypass safety checks)
./bin/update-shell-starter --force
```

### Manual Migration Scripts

For complex migrations, you may need custom scripts:

```bash
#!/bin/bash
# migrate-to-v02.sh - Custom migration script for 0.2.0

set -euo pipefail

echo "Migrating to Shell Starter 0.2.0..."

# Backup current state
cp -r lib lib.backup.$(date +%Y%m%d-%H%M%S)

# Update function names
find bin lib -name "*.sh" -type f -exec sed -i.bak \
    -e 's/log_info/log::info/g' \
    -e 's/log_warn/log::warn/g' \
    -e 's/log_error/log::error/g' \
    -e 's/log_debug/log::debug/g' \
    {} \;

# Test scripts
echo "Testing updated scripts..."
for script in bin/*; do
    [[ -x "$script" ]] || continue
    echo "Testing $script..."
    "$script" --help >/dev/null || echo "Warning: $script --help failed"
done

echo "Migration complete! Please test your scripts thoroughly."
```

## 🔍 Compatibility Checking

### Version Detection

Check what version of Shell Starter your project uses:

```bash
# Check tracked version
cat .shell-starter-version

# Check actual library version (if available)
grep -r "SHELL_STARTER_VERSION" lib/ 2>/dev/null || echo "Version not found in libraries"

# Check for version mismatches
./bin/update-shell-starter --check
```

### Function Compatibility Test

Test if your scripts use deprecated functions:

```bash
#!/bin/bash
# check-compatibility.sh - Check for deprecated function usage

deprecated_functions=(
    "log_info" "log_warn" "log_error" "log_debug"
    "start_spinner" "stop_spinner"
)

echo "Checking for deprecated function usage..."

for func in "${deprecated_functions[@]}"; do
    if grep -r "$func" bin/ lib/ 2>/dev/null; then
        echo "⚠️ Found deprecated function: $func"
    fi
done

echo "Compatibility check complete."
```

## 📚 Additional Resources

- **Changelog:** See [CHANGELOG.md](../CHANGELOG.md) for detailed version history
- **API Documentation:** See [docs/api.md](api.md) for current API reference
- **Examples:** See [docs/examples.md](examples.md) for updated usage patterns
- **Support:** Open an issue at [shell-starter repository](https://github.com/jeromecoloma/shell-starter/issues)

## 🆘 Troubleshooting

### Common Migration Issues

#### Issue: "Command not found" errors after update

**Cause:** Function names changed in breaking update
**Solution:** Update function calls to use new namespace syntax

```bash
# Find all old function calls
grep -r "log_" bin/ lib/

# Replace with new syntax
sed -i 's/log_info/log::info/g' affected_files
```

#### Issue: Scripts show no colors after update

**Cause:** Color variable names changed
**Solution:** Update to new `COLOR_` prefixed variables

```bash
# Check for old color variables
grep -r "\${RED}" bin/ lib/

# Update to new format
sed -i 's/\${RED}/\${COLOR_RED}/g' affected_files
```

#### Issue: Spinner not working after update

**Cause:** Spinner API changed to namespace syntax
**Solution:** Update spinner function calls

```bash
# Update spinner calls
sed -i 's/start_spinner/spinner::start/g' affected_files
sed -i 's/stop_spinner/spinner::stop/g' affected_files
```

### Getting Help

If you encounter issues during migration:

1. **Check this guide** for your specific version transition
2. **Run with --dry-run** to preview changes before applying
3. **Create backups** before attempting migration
4. **Test in development** before updating production
5. **Open an issue** if you find problems not covered here

### Emergency Rollback

If migration fails and you need to rollback:

```bash
# Restore from automatic backup
cp -r lib.backup-YYYYMMDD-HHMMSS/* lib/

# Or manually restore specific files
git checkout HEAD~1 -- lib/

# Verify rollback
cat .shell-starter-version
```

Remember: Shell Starter's migration tools are designed to be safe, but always backup your work before major updates.