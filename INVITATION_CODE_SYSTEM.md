# Invitation Code System

This system allows admins and librarians to create invitation codes that teachers can use to register. Each code is single-use and expires after 6 hours.

## Features

- **Single-use codes**: Each invitation code can only be used once
- **6-hour expiration**: Codes automatically expire after 6 hours
- **Admin control**: Only admins and librarians can create invitation codes
- **Automatic cleanup**: Expired codes can be cleaned up automatically
- **Tracking**: Full audit trail of who created and used each code

## How It Works

1. **Admin creates invitation code**: Admin/librarian creates a new invitation code
2. **Code is generated**: System generates a unique 8-character uppercase code
3. **Teacher registers**: Teacher uses the code during registration
4. **Code is consumed**: Code is marked as used and cannot be reused
5. **Automatic expiration**: Codes expire after 6 hours if not used

## API Endpoints

### Create Invitation Code
```
POST /book-library/invitation-codes/create
Authorization: Bearer <token>
```
**Response:**
```json
{
  "id": 1,
  "code": "ABC123XY",
  "created_by": 1,
  "created_at": "2025-06-28T07:44:11.888621Z",
  "expires_at": "2025-06-28T13:44:11.888621Z",
  "is_used": false,
  "used_by": null,
  "used_at": null
}
```

### List Invitation Codes
```
GET /book-library/invitation-codes
Authorization: Bearer <token>
```
**Response:**
```json
[
  {
    "id": 1,
    "code": "ABC123XY",
    "created_by": 1,
    "created_at": "2025-06-28T07:44:11.888621Z",
    "expires_at": "2025-06-28T13:44:11.888621Z",
    "is_used": false,
    "used_by": null,
    "used_at": null
  }
]
```

### Delete Invitation Code
```
DELETE /book-library/invitation-codes/{code_id}/delete
Authorization: Bearer <token>
```

### Cleanup Expired Codes
```
POST /book-library/invitation-codes/cleanup
Authorization: Bearer <token>
```
**Response:**
```json
{
  "deleted_count": 5
}
```

## Teacher Registration

When registering as a teacher, use the `invitation_code` field instead of the old `teacher_code`:

```json
{
  "email": "teacher@nlenau.ro",
  "password": "securepassword123",
  "first_name": "John",
  "last_name": "Doe",
  "is_teacher": true,
  "invitation_code": "ABC123XY"
}
```

## Management Commands

### Cleanup Expired Invitation Codes
```bash
# Test run (shows what would be deleted)
python manage.py cleanup_expired_invitations --dry-run

# Actual cleanup
python manage.py cleanup_expired_invitations
```

## Database Model

### InvitationCode
- `code`: Unique 8-character uppercase code
- `created_by`: User who created the code
- `created_at`: When the code was created
- `expires_at`: When the code expires (6 hours after creation)
- `is_used`: Whether the code has been used
- `used_by`: User who used the code (if used)
- `used_at`: When the code was used (if used)

## Methods

### is_expired()
Returns `True` if the code has expired.

### is_valid()
Returns `True` if the code is valid (not used and not expired).

### use_code(user)
Marks the code as used by a specific user. Raises `ValueError` if code is invalid.

### generate_code()
Generates a unique 8-character uppercase code.

## Error Messages

### Invalid Code
```
{"invitation_code": "Invalid invitation code"}
```

### Expired Code
```
{"invitation_code": "This invitation code has expired"}
```

### Already Used Code
```
{"invitation_code": "This invitation code has already been used"}
```

### Missing Code for Teacher
```
{"invitation_code": "Invitation code is required for teacher registration"}
```

## Security

- Only admins and librarians can create invitation codes
- Codes are single-use and cannot be reused
- Codes automatically expire after 6 hours
- Full audit trail of code creation and usage
- Codes are case-insensitive (automatically converted to uppercase)

## Testing

Run the test script to verify the system works:
```bash
python test_invitation_system.py
```

## Migration from Old System

The old hardcoded `Teacher101` code has been replaced with this invitation system. Teachers now need a valid invitation code to register.

## Scheduling Cleanup

You can schedule automatic cleanup of expired codes using cron or similar:

```bash
# Run every hour
0 * * * * cd /path/to/lenbrary/backend && python manage.py cleanup_expired_invitations
``` 