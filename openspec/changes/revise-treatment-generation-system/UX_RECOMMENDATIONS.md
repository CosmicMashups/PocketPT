# Treatment Adherence & UX Enhancement Recommendations

This document outlines recommended UX and logic enhancements to improve user adherence to the treatment sequence. These recommendations are **NOT part of the current implementation scope** and should be reviewed and approved separately before implementation.

## 1. Daily Treatment Reminders

### Recommendation
Implement push notifications/local reminders to prompt users to complete their daily treatments, especially the mandatory sequence (T001 → T002 → T003).

### Implementation Approach
- Add notification scheduling in `UserSettings` or dedicated reminder service
- Allow users to set preferred reminder times (e.g., morning, afternoon, evening)
- Show reminder card in dashboard when treatments are due
- Support snooze/reschedule functionality

### Benefits
- Increases treatment completion rates
- Ensures users don't forget foundational treatments
- Supports habit formation

### Considerations
- Respect user notification preferences
- Provide opt-out option
- Handle timezone differences appropriately
- Support multiple reminders per day if needed

## 2. Sequence Locking: Progressive Unlocking

### Recommendation
Implement progressive unlocking where users must complete T001 before T002 becomes available, and T002 before T003 becomes available.

### Implementation Approach
- Track treatment completion status in `UserProgress` or new `TreatmentProgress` model
- Disable/disable UI elements for locked treatments
- Show visual indicators (locked icon, grayed out) for unavailable treatments
- Unlock next treatment automatically upon completion of previous

### Benefits
- Ensures users follow proper treatment sequence
- Prevents skipping foundational steps
- Provides clear treatment progression guidance

### Considerations
- Allow "unlock all" option for advanced users (with disclaimer)
- Provide clear explanation why sequence matters
- Handle edge cases (user completes T001 but not T002 - should T003 remain locked?)

## 3. Visual Progress Indicators

### Recommendation
Add visual progress indicators showing treatment completion status and sequence progress.

### Implementation Approach
- Progress bar showing: T001 → T002 → T003 → Optional treatments
- Checkmarks for completed treatments
- Current treatment highlighted/emphasized
- Weekly/daily progress overview

### Benefits
- Provides immediate visual feedback
- Motivates completion through gamification
- Shows clear path forward

### Considerations
- Keep UI clean and not overwhelming
- Ensure accessibility (colorblind-friendly indicators)
- Support both daily and weekly views

## 4. Chronological Tracking with Timestamps

### Recommendation
Track exact timestamps when each treatment is completed, allowing analysis of treatment adherence patterns.

### Implementation Approach
- Add `TreatmentHistory` model similar to `ExerciseHistory`
- Store completion timestamp, treatment ID, and any notes
- Support querying by date range, treatment ID, completion status
- Display timeline view of treatment completions

### Benefits
- Enables data-driven insights on treatment adherence
- Supports reporting and analytics
- Helps identify patterns (when users complete treatments, which are skipped)

### Considerations
- Privacy considerations for health data
- Storage space for long-term history
- Performance with large history datasets

## 5. Notifications for Skipped or Delayed Treatments

### Recommendation
Send notifications when users skip or delay treatments beyond a threshold (e.g., 24 hours since scheduled time).

### Implementation Approach
- Track scheduled vs actual completion times
- Calculate delay/skip detection logic
- Trigger notifications for delayed treatments
- Provide gentle encouragement, not punitive messaging

### Benefits
- Helps users catch up on missed treatments
- Maintains treatment momentum
- Provides accountability

### Considerations
- Avoid notification fatigue (limit frequency)
- Provide helpful context (why treatment is important)
- Support "dismiss" or "reschedule" actions
- Handle timezone and scheduling edge cases

## 6. Treatment Streaks and Adherence Scoring

### Recommendation
Implement streak tracking and adherence scoring to gamify treatment completion.

### Implementation Approach
- Calculate daily streak (consecutive days with all mandatory treatments completed)
- Calculate adherence score (percentage of scheduled treatments completed)
- Display streaks prominently in dashboard
- Provide achievements/badges for milestones (7-day streak, 30-day streak, etc.)

### Benefits
- Increases motivation through gamification
- Makes treatment completion feel rewarding
- Encourages long-term adherence

### Considerations
- Balance gamification with medical seriousness
- Ensure streaks don't cause anxiety if broken
- Provide ways to "recover" from broken streaks
- Consider multiple streak types (daily, weekly, mandatory-only)

## 7. Auto-logging Each Treatment Step After Completion

### Recommendation
Automatically log treatment completion when user marks a treatment as done, with optional notes or pain scale.

### Implementation Approach
- Add "Mark as Complete" button to each treatment card
- Prompt for optional notes or pain scale after completion
- Automatically timestamp and save to `TreatmentHistory`
- Update progress indicators and streaks in real-time

### Benefits
- Reduces friction in tracking treatments
- Captures valuable completion data
- Supports habit formation through immediate feedback

### Considerations
- Make completion action prominent but not intrusive
- Support batch completion (mark all today's treatments at once)
- Handle offline completion (queue and sync when online)
- Prevent accidental multiple completions

## 8. Treatment Plan Visualization

### Recommendation
Provide a visual calendar/timeline view showing treatment plan schedule and completion status.

### Implementation Approach
- Calendar widget showing daily treatment assignments
- Color-coding for completion status (completed, in-progress, missed, upcoming)
- Weekly/monthly overview views
- Filter by treatment type (mandatory vs optional)

### Benefits
- Helps users plan treatment schedule
- Provides clear overview of treatment journey
- Makes it easy to catch up on missed treatments

### Considerations
- Performance with long treatment plans (weeks/months)
- Mobile-friendly calendar UI
- Support for treatment frequency (daily, every other day, etc.)
- Integration with system calendar (optional)

## 9. Smart Treatment Recommendations

### Recommendation
Use completion history and pain tracking to recommend optional treatments or suggest treatment adjustments.

### Implementation Approach
- Analyze treatment completion patterns and pain levels
- Recommend additional optional treatments based on pain trends
- Suggest treatment schedule adjustments based on adherence patterns
- Provide personalized tips based on user's treatment journey

### Benefits
- Personalizes treatment experience
- Adapts to user's needs and patterns
- Provides value beyond basic tracking

### Considerations
- Ensure recommendations are medically sound
- Provide clear disclaimers (not medical advice)
- Allow users to dismiss/reject recommendations
- Balance automation with user control

## 10. Treatment Reminder Preferences

### Recommendation
Allow users to customize treatment reminders with granular control over timing, frequency, and content.

### Implementation Approach
- Settings page for treatment reminders
- Per-treatment reminder preferences (some treatments more important)
- Custom reminder messages
- Quiet hours / do-not-disturb periods
- Treatment-specific reminder times

### Benefits
- Respects user preferences and schedules
- Increases likelihood of reminder effectiveness
- Reduces notification fatigue

### Considerations
- Default sensible settings (don't overwhelm with options)
- Test reminder effectiveness across different user types
- Support multiple reminder strategies (push, in-app, email)

## Implementation Priority Recommendation

**High Priority (Quick Wins):**
1. Auto-logging treatment completion (#7)
2. Visual progress indicators (#3)
3. Chronological tracking (#4)

**Medium Priority (Significant Impact):**
4. Daily treatment reminders (#1)
5. Treatment streaks and adherence scoring (#6)
6. Sequence locking (#2)

**Lower Priority (Nice-to-Have):**
7. Skipped treatment notifications (#5)
8. Treatment plan visualization (#8)
9. Smart recommendations (#9)
10. Advanced reminder preferences (#10)

## Next Steps

1. Review these recommendations with stakeholders
2. Prioritize based on user research and feedback
3. Create separate OpenSpec proposals for approved enhancements
4. Implement incrementally, starting with high-priority items
5. Measure impact on treatment adherence rates

