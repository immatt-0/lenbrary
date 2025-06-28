# Email Verification with 6-Hour Expiration

This implementation adds automatic expiration to email verification links. Unverified accounts are automatically deleted after 6 hours if the email is not verified.

## Features

- **6-hour expiration**: Email verification links expire after 6 hours
- **Automatic cleanup**: Expired unverified accounts are automatically deleted
- **User-friendly messages**: Clear error messages when links expire
- **Multiple cleanup methods**: Both Django management command and standalone script

## How It Works

1. When a user registers, an `EmailVerification` record is created with a timestamp
2. The verification link includes a token that expires after 6 hours
3. If a user tries to verify an expired link, they see an error message
4. If a user tries to login with an expired verification, their account is automatically deleted
5. A cleanup script can be run periodically to remove expired accounts

## Cleanup Methods

### 1. Django Management Command

```bash
# Test run (shows what would be deleted)
python manage.py cleanup_expired_verifications --dry-run

# Actual cleanup
python manage.py cleanup_expired_verifications
```

### 2. Standalone Script

```bash
# Test run
python cleanup_expired_accounts.py --dry-run

# Actual cleanup
python cleanup_expired_accounts.py
```

## Setting Up Automatic Cleanup

### Option 1: Cron Job (Linux/Mac)

Add to your crontab to run every hour:

```bash
# Edit crontab
crontab -e

# Add this line (adjust path as needed)
0 * * * * cd /path/to/lenbrary/backend && python cleanup_expired_accounts.py
```

### Option 2: Windows Task Scheduler

1. Open Task Scheduler
2. Create a new Basic Task
3. Set trigger to run every hour
4. Set action to start a program
5. Program: `python`
6. Arguments: `cleanup_expired_accounts.py`
7. Start in: `C:\path\to\lenbrary\backend`

### Option 3: Systemd Timer (Linux)

Create `/etc/systemd/system/lenbrary-cleanup.service`:
```ini
[Unit]
Description=Lenbrary Email Verification Cleanup
After=network.target

[Service]
Type=oneshot
User=your-user
WorkingDirectory=/path/to/lenbrary/backend
ExecStart=/usr/bin/python cleanup_expired_accounts.py
```

Create `/etc/systemd/system/lenbrary-cleanup.timer`:
```ini
[Unit]
Description=Run Lenbrary cleanup every hour
Requires=lenbrary-cleanup.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl enable lenbrary-cleanup.timer
sudo systemctl start lenbrary-cleanup.timer
```

## Error Messages

### Expired Link
When a user clicks an expired verification link, they see:
> "Linkul de verificare a expirat (6 ore). Contul tău a fost șters automat. Poți să te înregistrezi din nou."

### Expired Login Attempt
When a user tries to login with an expired verification, they see:
> "Linkul de verificare a expirat (6 ore). Contul a fost șters automat. Poți să te înregistrezi din nou."

## Testing

To test the expiration functionality:

1. Register a new user
2. Wait for the verification email
3. Don't click the verification link
4. After 6 hours, try to:
   - Click the verification link (should show expired message)
   - Login with the account (should delete account and show expired message)

## Database Impact

- The `EmailVerification` model now has an `is_expired()` method
- No database schema changes required
- Expired accounts are automatically cleaned up to prevent database bloat

## Security Benefits

- Prevents accumulation of unverified accounts
- Reduces database size
- Forces users to verify their email promptly
- Prevents abuse of the registration system 