## Why
The current dialog implementations across the application have inconsistent styling, potential overflow issues, and lack responsive design patterns. Users experience poor visual hierarchy, inconsistent spacing, and dialogs that may not display properly on different screen sizes. The existing dialogs in main.dart, main_new.dart, home_dialog.dart, and dashboard_page.dart need unified, modern styling with proper overflow protection and responsive layout.

## What Changes
- **BREAKING**: Standardize dialog styling across all application dialogs
- **BREAKING**: Implement responsive dialog layouts with overflow protection
- **BREAKING**: Create reusable dialog components with consistent theming
- **BREAKING**: Update existing dialog implementations to use new standardized components
- Add responsive design patterns for different screen sizes and orientations
- Implement proper overflow handling for long content
- Create consistent visual hierarchy and spacing
- Add accessibility improvements for dialog interactions
- Ensure dark/light theme compatibility across all dialogs

## Impact
- Affected specs: user interface, accessibility, responsive design
- Affected code: `lib/main.dart`, `lib/main_new.dart`, `lib/home_dialog.dart`, `lib/dashboard/dashboard_page.dart`, new dialog components
- Breaking changes to dialog styling require testing across all dialog implementations
- New responsive patterns require validation on different device sizes
- Accessibility improvements require testing with screen readers and accessibility tools

