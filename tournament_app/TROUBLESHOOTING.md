# Troubleshooting Guide

## Authentication Issues

### "AuthApiException" or Email Validation Errors

**Possible Causes:**

1. **Email Confirmation Required**
   - By default, Supabase requires email confirmation
   - **Solution:**
     - Go to Supabase Dashboard → Authentication → Settings
     - Under "Email Auth", disable "Enable email confirmations" (for development)
     - Or check your email inbox for the confirmation link

2. **Email Already Registered**
   - The email address is already in the database
   - **Solution:**
     - Try logging in instead of signing up
     - Or use a different email address
     - Or delete the user from Supabase Dashboard → Authentication → Users

3. **Invalid Email Format**
   - Email doesn't match the validation pattern
   - **Solution:**
     - Use a proper email format: `user@domain.com`
     - Make sure there are no spaces or special characters

4. **Password Too Weak**
   - Supabase requires minimum 6 characters by default
   - **Solution:**
     - Use a password with at least 6 characters
     - Include letters, numbers, and special characters

5. **Rate Limiting**
   - Too many signup attempts in a short time
   - **Solution:**
     - Wait a few minutes before trying again
     - Check Supabase Dashboard → Authentication → Rate Limits

### Fix Email Confirmation for Development

1. Go to: https://ydxeavrjmaujmoysrhqx.supabase.co
2. Navigate to **Authentication** → **Settings** → **Auth Providers**
3. Click on **Email**
4. **Disable** "Enable email confirmations"
5. Click **Save**

Now users can sign up without needing to confirm their email (good for development).

### Check if User Was Created

1. Go to Supabase Dashboard → **Authentication** → **Users**
2. Look for the email you tried to register
3. If you see it, the user was created successfully
4. You can manually confirm the user by clicking on them and clicking "Confirm"

## Database Connection Issues

### "Failed to connect to Supabase"

**Solution:**
1. Check your Supabase URL and anon key in `lib/config/supabase_config.dart`
2. Verify your Supabase project is not paused
3. Check your internet connection

### "Row Level Security policy violation"

**Solution:**
1. Make sure you ran all the RLS policies from `setup_complete.sql`
2. Check Supabase Dashboard → Database → Policies
3. Verify policies exist for all tables

## Login Issues

### "Invalid login credentials"

**Possible Causes:**
1. Wrong email or password
2. User doesn't exist
3. Email not confirmed (if email confirmation is enabled)

**Solution:**
1. Double-check email and password
2. Try the "Forgot Password" link
3. Make sure you registered first
4. Check if email confirmation is required

### User profile not loading after login

**Solution:**
1. Check browser console for errors
2. Verify the `handle_new_user()` trigger was created in Supabase
3. Go to Supabase Dashboard → Database → Functions
4. Verify the trigger exists

## App Not Running

### "Flutter command not found"

**Solution:**
```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from https://flutter.dev
```

### "No devices found"

**Solution:**
```bash
# List available devices
flutter devices

# Run on Chrome
flutter run -d chrome

# Run on Windows
flutter run -d windows
```

### Build errors

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Hot Reload Not Working

**Solution:**
1. Save the file you edited (Ctrl/Cmd + S)
2. In the terminal where Flutter is running, press `r` for hot reload
3. Or press `R` for hot restart
4. Or just save the file again - Flutter auto-reloads on save

## Common Supabase Configuration Issues

### Tables not created

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Copy all SQL from `setup_complete.sql`
3. Run it again
4. Check for any error messages

### RLS policies not working

**Solution:**
1. Make sure RLS is enabled on all tables
2. Verify policies are created
3. Check policy syntax in SQL Editor
4. Test with different user roles

## Getting More Help

### View Console Logs

**In Chrome:**
1. Press F12 to open Developer Tools
2. Go to "Console" tab
3. Look for error messages in red

**In Flutter:**
1. Check the terminal where you ran `flutter run`
2. Look for error stack traces

### Enable Debug Mode

Supabase logs are already enabled. Check the terminal for:
```
supabase.supabase_flutter: INFO: ...
```

### Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| `User already registered` | Email already exists | Use login or different email |
| `Invalid login credentials` | Wrong email/password | Check credentials or reset password |
| `Email not confirmed` | Email verification pending | Check email or disable confirmation |
| `Password should be at least 6 characters` | Password too short | Use longer password |
| `Invalid email` | Bad email format | Use proper email format |
| `AuthApiException` | General auth error | Check Supabase settings and error details |

## Still Having Issues?

1. Check the full error message in the terminal
2. Look at browser console (F12)
3. Verify Supabase Dashboard → Authentication → Settings
4. Make sure email provider is enabled
5. Try with a completely different email address
6. Clear browser cache and reload

## Test Account

For testing purposes, try creating an account with:
- Email: `test@example.com`
- Password: `test123456`
- Name: `Test User`
- Role: `Team Captain`

If this works, the issue is likely with the specific email you were using.
