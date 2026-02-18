## Why

The PocketPT codebase currently uses rule-based logic for exercise selection, treatment generation, and rehabilitation planning. While functional, these systems rely on hardcoded thresholds, exact string matching, and random selection from filtered results. A comprehensive technical analysis is needed to identify meaningful AI enhancement opportunities that can improve personalization, automate decision-making, and introduce learning-based recommendations while remaining grounded in the existing architecture.

## What Changes

- **Technical Analysis**: Comprehensive codebase analysis documenting all current thesis components (pose estimation, pain recognition, exercise/treatment generation, pain tracking, filtering mechanisms)
- **AI Opportunity Identification**: Systematic identification of AI enhancement opportunities that replace hardcoded logic, improve personalization, and introduce learning
- **Mini AI Prototype**: Implementation of one lightweight AI enhancement (<2 hours) that demonstrates practical value using existing data
- **Analysis Documentation**: Structured reflection template documenting the AI method, dataset, results, challenges, and research quality improvements

## Impact

- **Affected specs**: New capability `ai-analysis` for documenting AI opportunities and prototype implementation
- **Affected code**: 
  - Analysis documentation (new files)
  - AI prototype implementation (new service/model)
  - Integration points with existing exercise generation, pain tracking, or recommendation systems
- **Research value**: Provides evidence-based AI enhancement recommendations grounded in actual codebase implementation
