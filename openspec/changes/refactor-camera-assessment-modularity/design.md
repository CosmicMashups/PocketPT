## Context

The current `c_camera.dart` file contains 1628 lines with mixed responsibilities:
- Camera UI components and layout management
- Real-time pose detection and processing
- Assessment logic for multiple muscle groups (triceps, shoulders, hamstrings, calves)
- Clinical threshold calculations and pain scale mapping
- AI model integration and data persistence

This monolithic structure creates maintenance challenges and reduces code reusability. The assessment logic should be modularized while preserving the existing clinical accuracy and real-time performance.

## Goals / Non-Goals

### Goals
- Separate assessment logic from UI components for better maintainability
- Create reusable assessment modules that can be tested independently
- Maintain existing clinical thresholds and assessment accuracy
- Preserve real-time assessment performance and AI model integration
- Enable future assessment module extensions without UI changes

### Non-Goals
- Changing clinical assessment algorithms or thresholds
- Modifying the user interface or camera functionality
- Altering AI model integration or pose detection accuracy
- Breaking existing data persistence or pain scale mapping

## Decisions

### Decision: Modular Assessment Architecture
**What**: Extract assessment logic into dedicated modules under `lib/assessment/arom/`
**Why**: Enables independent testing, better code organization, and future extensibility
**Alternatives considered**: 
- Service layer approach: Would require more complex dependency injection
- Mixin-based approach: Would still couple logic with UI components

### Decision: Consistent API Interface
**What**: Standardize assessment module APIs with consistent input/output patterns
**Why**: Simplifies integration and enables polymorphic assessment handling
**Alternatives considered**:
- Custom interfaces per module: Would increase complexity in camera UI
- Generic assessment interface: Would lose type safety and clarity

### Decision: Preserve Existing Integration Points
**What**: Maintain current pose detection service integration and data flow
**Why**: Minimizes risk and preserves existing functionality
**Alternatives considered**:
- New assessment service layer: Would require more extensive refactoring
- Event-driven architecture: Would add complexity without clear benefits

## Risks / Trade-offs

### Risk: Performance Regression
**Mitigation**: Maintain existing throttling and processing patterns in camera UI

### Risk: Breaking Existing Functionality
**Mitigation**: Comprehensive testing and gradual migration approach

### Risk: Increased Code Complexity
**Mitigation**: Clear API documentation and consistent module patterns

## Migration Plan

1. **Phase 1**: Extract assessment modules with identical logic
2. **Phase 2**: Update camera UI to use new modules
3. **Phase 3**: Remove original inline logic
4. **Phase 4**: Add comprehensive testing

## Open Questions

- Should we create a shared assessment base class for common functionality?
- Do we need assessment module configuration for different clinical contexts?
