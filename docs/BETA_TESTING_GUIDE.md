# Dona Pro - Beta Testing Guide

Welcome to the Dona Pro beta! This guide will help you get started and make the most of testing.

## What is Dona Pro?

Dona Pro is your AI-powered life assistant that helps you:
- Plan your day and week intelligently
- Run autopilots that actually execute tasks (not just suggest them)
- Stay focused with structured work sessions
- Maintain important relationships
- Organize your inbox and tasks

## Getting Started

### 1. Installation

Install the beta build you received via TestFlight (iOS) or direct APK (Android).

### 2. First Launch - Onboarding

On first launch, you'll see a 3-page onboarding flow:

**Page 1: Welcome**
- Learn what Dona can do
- Tap "Next" to continue

**Page 2: Select Your Profile**

Choose the option that best describes you:

- **Student**: Focus on studying, exams, assignments
- **Founder/CEO**: Focus on strategic work, weekly reviews, deep focus
- **Professional**: Focus on inbox management, task organization
- **Mixed**: Flexible combination of all modes

**Page 3: Choose Your Persona**

Based on your profile, you'll see recommended AI personas:
- **Student** → Study Coach
- **Founder** → Founder/CEO persona
- **Professional** → Professional persona

Tap "Get Started" to enter Dona!

### 3. Main Screen - Command Center

The **Command Center** is your home base. You'll see:

- **Context Summary**: "Good morning! Here's what matters today."
- **Dona Recommends**: AI-generated suggestions based on your context
- **Top Priorities**: Your most urgent tasks and events
- **Quick Actions**: Autopilot buttons (Plan My Day, Study Session, etc.)

### 4. Try Demo Mode (Optional)

Want to see how Dona looks with data? Try Demo Mode:

1. Tap **Settings** (gear icon)
2. Scroll to **Demo & Testing**
3. Tap **Enter Demo Mode**
4. Confirm

This generates realistic sample data (autopilot history, etc.) so you can explore features.

**To exit**: Settings → Demo & Testing → Exit Demo Mode

## Key Features to Test

### Autopilots (Free Tier)

**Plan My Day** (1/day in Free tier):
1. Tap "Plan My Day" in Command Center
2. Dona generates a personalized daily plan
3. Review the plan preview
4. Tap "Execute Plan" to create tasks/events

**Study Session** (2/day in Free tier):
1. Add a course and exam in the app (if Student profile)
2. Tap "Study Session"
3. Dona creates a study plan
4. Execute the plan

### Autopilots (Premium/Trial)

If you're in Premium Trial mode, you can also try:

- **Weekly Review**: Review last week, plan upcoming week (Sundays recommended)
- **Focus Mode**: 2-hour deep work session with Pomodoro breaks
- **Triage**: Organize inbox and tasks (requires Gmail/Tasks connected)
- **Relationships**: Schedule check-ins with important contacts

**Note**: Free tier blocks premium features with an upgrade prompt.

### Command Palette

**Access**: Tap the **"Quick Actions"** button (bottom center of Command Center)

**Features**:
- Search all commands, autopilots, navigation
- Type to filter (e.g., "plan", "history", "settings")
- Use arrow keys to navigate, Enter to select
- Press Escape to close

### Autopilot History

See all your past autopilot runs:

1. Settings → Support → Autopilot History
2. Filter by type (Plan My Day, Study, etc.)
3. Filter by period (All Time, Last 7 Days, Last 30 Days)
4. Tap an entry to see details

### Feedback & Bug Reports

Found a bug or have a suggestion?

1. Settings → Support → Feedback & Support
2. Choose:
   - **Bug Report**: Something's broken
   - **Feature Idea**: Suggestion for improvement
   - **General**: Other feedback
3. Fill in title and description
4. Optional: Include your email for follow-up
5. Tap "Continue"
6. Choose "Copy to Clipboard" or "Email Support"

**Privacy**: We only collect anonymized logs and app info - no personal messages or content. See what's included in the dialog.

### About Screen

Check app version and info:

1. Settings → About → About
2. See version number, platform, credits
3. Tap "Open Source Licenses" to view third-party libraries

## Test Scenarios

### Scenario 1: Student Flow (15 minutes)

1. **Onboard** as Student → Choose Study Coach
2. **Add Course**: Settings → (placeholder for now)
3. **Run Study Autopilot**: Create study plan for upcoming exam
4. **Check History**: Settings → Autopilot History → See execution
5. **Try Daily Limit**: Run Plan My Day, then try again (should hit 1/day limit)
6. **Send Feedback**: Report any issues via Feedback screen

### Scenario 2: Founder Flow (20 minutes)

1. **Onboard** as Founder → Choose Founder/CEO persona
2. **Weekly Review**: (Premium) Review past week, plan upcoming
3. **Focus Mode**: (Premium) 2-hour deep work session
4. **Plan My Day**: Morning planning autopilot
5. **Check History**: Review all executions
6. **Command Palette**: Try searching for commands

### Scenario 3: Busy Professional Flow (15 minutes)

1. **Onboard** as Professional
2. **Plan My Day**: Morning routine
3. **Triage**: (Premium) Organize inbox and tasks
4. **Check Priorities**: Review top priorities in Command Center
5. **Demo Mode**: Enter demo mode to see more history
6. **Exit Demo**: Clear demo data

## What to Look For

### Critical Issues

Report immediately if you encounter:
- App crashes
- Data loss
- Freezing/hanging
- Login failures (Google OAuth)
- Privacy concerns (personal data visible where it shouldn't be)

### High Priority

Report these if you see them:
- Autopilots fail to execute
- Confusing UI/UX
- Missing features from Free/Premium tiers
- Upgrade prompts appearing too frequently
- Performance issues (slow loading, lag)

### Nice to Have

Helpful feedback:
- Feature suggestions
- UI/design improvements
- Better copy/messaging
- Onboarding flow improvements

## Known Limitations (Not Bugs)

- **Billing not implemented**: Premium mode set manually in Settings (for now)
- **Limited integrations**: Only Google Calendar and Tasks currently
- **No cloud sync**: All data local to your device
- **Demo mode clears ALL history**: Not just demo entries (will improve)

## Privacy Reminders

- **All data is local**: Stored only on your device
- **No tracking**: We don't send analytics or telemetry
- **Feedback is safe**: Only anonymized logs and app info, no personal content
- **You control data**: Export or delete anytime via Settings → Privacy & Data

## Feedback Channels

**In-App**: Settings → Feedback & Support (preferred)

**Email**: support@dona.ai (if in-app fails)

**GitHub Issues**: https://github.com/dona-ai/dona-pro/issues (for developers)

## Tips for Effective Testing

1. **Try all profiles**: Test Student, Founder, and Professional flows
2. **Hit the limits**: Try exceeding free tier limits to see upgrade prompts
3. **Use Command Palette**: Test search and keyboard shortcuts
4. **Check History**: Verify autopilots are recorded correctly
5. **Enter/Exit Demo Mode**: Test data generation and cleanup
6. **Submit feedback**: Even small issues help us improve!

## Troubleshooting

**App won't start**:
- Clear app data and reinstall
- Check device storage

**Autopilot fails**:
- Check logs via Feedback screen
- Try again or report bug

**Can't access premium features**:
- Settings → (placeholder for app mode switcher)
- In beta, you may need manual mode change

**Demo mode issues**:
- Exit demo mode and re-enter
- If stuck, clear app data (loses all data)

## Thank You!

Your testing helps make Dona Pro better for everyone. We appreciate your time and feedback!

**Questions?** Email support@dona.ai

**Want to contribute?** Check out our GitHub: https://github.com/dona-ai/dona-pro

---

**Version**: 1.0.0 Beta 1
**Last Updated**: November 2025
