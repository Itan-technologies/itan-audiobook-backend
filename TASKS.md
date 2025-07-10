
## Prerequisites tasks
- Installing gem bundles
- Check for errors with rubocop
- Install PostgreSQL and connect to the project
- Create a tasks file for tracking the advancements of the project

## Main Tasks (Prioritized)
### 1. Readers Authentication
- Implement "Forgot Password" functionality
- Integrate Google OAuth for readers
- Add 2FA (Two-Factor Authentication) for readers
- Add reCAPTCHA to authentication forms
- Test all authentication flows

### 2. Readers Storefront
- Implement book listing page for readers
- Add filtering options (genre, author, etc.)
- Test storefront UI and filtering

### 3. Readers Sign-In Dashboard
- Design dashboard layout for signed-in readers
- Display relevant reader information (recent books, recommendations, etc.)

### 4. Payment Receipt for Readers
- Generate payment receipt after purchase
- Email receipt to reader
- Add receipt download option in dashboard

### 5. Free Chapter One
- Make chapter one of every book accessible for free
- Restrict access to other chapters for non-purchasers

### 6. Author’s Google OAuth
- Integrate Google OAuth for authors
- Update author registration/login views
- Test author OAuth flow

### 7. Author’s Book Link
- Add unique link to each author’s book
- Display link in author dashboard

### 8. Change App Email for Author Notifications
- Update sender email in mailer configuration
- Test email delivery to authors with new email

### 9. Book Persistent Page
- Implement persistent (static) page for each book
- Ensure SEO-friendly URLs

### 10. Testing & Linters
- Write tests for controllers
- Write tests for models
- Run and fix issues flagged by linters

### 11. Cloud Plexo Backend Errors
- Review error logs on Cloud Plexo
- Debug and fix backend errors
- Coordinate with Cloud Plexo support if needed

## Day 1
### Completed Tasks
- Resolved the ruby version conflicts by changing the version `3.2.2` to `3.3.6`
- Install gems and updated the Gemfile.lock
- Added rubocop-rspec gem for error detections
- Automatic correction with rubocop in some files.

### Uncompleted Tasks
- Configure PostgreSQL in the database.yml file.

### Blockers
- Encountered some quit linters with some can be fixed automatically and others manually.

### Upcoming Tasks
- Configure PostgreSQL with Rails(basic local setup)
- Google authentication for both Authors and Readers.

## Day 2 - Author's Google Authentication
* 1. Install `omniauth-google-oauth2` and `omniauth-rails_csrf_protection` gems(already installed)
* 2. enable `OmniAuth` for authentication via `Google OAuth2` by adding code in the author devise model file.
* 
### Completed tasks
### Uncompleted tasks
### Blockers
### Upcoming tasks

