# UzaApp Authentication Flow Documentation

## Overview
The UzaApp now supports **password-based authentication** as the primary method for reconnecting to existing shops on new devices. OTP is only used for password recovery or initial verification.

## Authentication Flow

### 1. **First Time User - Creating a Shop**
When a user creates their first shop:

1. Fill in shop information (name, city, commune)
2. Enter contact details (phone, WhatsApp)
3. **Verification Step**:
   - Verify phone number via OTP (optional - can be skipped)
   - **Create a password** (optional but recommended)
     - Password allows easy login on other devices
     - Minimum 6 characters
     - Must be confirmed
4. Add shop details (description, logo, social media)
5. Preview and submit

**Important**: The password is hashed using SHA-256 before being stored locally and on the server.

### 2. **Reconnecting on a New Device**
When a user logs in on a new device:

1. Click "J'ai déjà un compte" (I already have an account)
2. **Default Method - Password Login**:
   - Enter phone number
   - Enter password
   - Click "Se connecter"
   - **Shop is automatically reconnected** - no OTP needed!

3. **Alternative Method - OTP Login** (if password forgotten):
   - Click "Utiliser un code OTP à la place"
   - Enter phone number
   - Receive SMS with verification code
   - Enter code
   - Shop is reconnected

### 3. **Password Reset/Change**
If a user wants to change their password:

1. Login with OTP verification
2. Go to profile settings
3. Set new password
4. New password is saved and can be used for future logins

## Key Features

### ✅ Password Benefits
- **No OTP required for reconnection** - Just phone + password
- **Secure** - SHA-256 hashing
- **Cross-device** - Works on any device
- **Optional** - Users can still use OTP only

### ✅ Automatic Shop Reconnection
When a user logs in (via password or OTP):
- System checks for existing shops linked to their phone number
- Automatically reconnects shops to the session
- No need to recreate the shop
- Works across different phone number formats (+243, 0, etc.)

### ✅ Dual Authentication Modes
1. **Password Mode** (Default)
   - Fast login
   - No SMS needed
   - Best for daily use

2. **OTP Mode** (Fallback)
   - For password recovery
   - For first-time verification
   - Requires SMS

## Technical Implementation

### Database Schema
```sql
-- Local Database (Drift)
class UserProfiles extends Table {
  TextColumn get passwordHash => text().nullable()();
}

-- Server Database (MySQL)
ALTER TABLE `users` 
ADD COLUMN `password_hash` VARCHAR(255) NULL AFTER `avatar_url`;
```

### Password Hashing
```dart
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}
```

### Authentication Methods

#### Password Login
```dart
await authService.signInWithPassword(
  phoneNumber: phone,
  password: password,
  onSuccess: () { /* Navigate to home */ },
  onFailed: (e) { /* Show error */ },
);
```

#### OTP Login
```dart
await authService.verifyPhone(
  phoneNumber: phone,
  onCodeSent: (verificationId) { /* Navigate to verification */ },
  onFailed: (e) { /* Show error */ },
);
```

## User Experience

### Login Screen UI
1. **Header**: "Connectez-vous pour retrouver votre boutique"
2. **Phone Input**: International phone field
3. **Password Input**: 
   - Shown by default
   - Show/hide toggle
   - Required field
4. **Button**: "Se connecter"
5. **Alternative**: "Utiliser un code OTP à la place"

### Shop Creation Screen UI
In the verification step (Step 3):
- OTP verification section (top)
- **Password creation section** (bottom) - Highlighted box with:
  - "Créer un mot de passe (optionnel)"
  - Explanation: "Vous permettra de vous connecter facilement sur d'autres appareils"
  - Password field
  - Confirm password field
  - Validation messages

## Migration Guide

### For Existing Deployments
1. Run the SQL migration:
   ```bash
   mysql -u username -p database_name < server/add_password_hash.sql
   ```

2. Users can now:
   - Continue using OTP (no change)
   - Set a password on next shop creation
   - Use password for future logins

### For New Users
1. Create shop
2. Optionally set password during verification
3. Login with password on any device

## Security Considerations

1. **Password Hashing**: SHA-256 hashing before storage
2. **No Plain Text**: Passwords never stored in plain text
3. **Local + Server**: Password hash synced to both
4. **Optional**: Users can choose OTP-only if preferred

## Error Messages

- "Mot de passe incorrect" - Wrong password
- "Aucun compte trouvé avec ce numéro. Veuillez créer une boutique d'abord." - No account exists
- "Impossible de vérifier les identifiants" - Sync service unavailable
- "Minimum 6 caractères" - Password too short
- "Les mots de passe ne correspondent pas" - Password confirmation mismatch

## Future Enhancements

Potential improvements:
- [ ] Password reset via OTP
- [ ] Biometric authentication (fingerprint/face)
- [ ] Two-factor authentication (OTP + Password)
- [ ] Password strength meter
- [ ] Remember device option
