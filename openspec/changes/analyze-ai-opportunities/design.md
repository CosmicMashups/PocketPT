## Context

PocketPT is a rehabilitation companion app with rule-based exercise/treatment generation. The codebase uses:
- CSV-based exercise filtering (exact string matching on Muscle_Involved, Pain_Level, Functional_Goal)
- Hardcoded treatment selection (always T001, T002, T003)
- Random selection from filtered exercises (no ranking or personalization)
- Pain history tracking without pattern analysis
- No learning from user outcomes or exercise effectiveness

The research goal is to identify AI opportunities that enhance the system beyond rule-based logic while remaining grounded in actual implementation.

## Goals / Non-Goals

### Goals
- Comprehensive technical analysis of all thesis components
- Identify AI opportunities that replace hardcoded logic
- Implement one lightweight prototype (<2 hours) demonstrating practical value
- Ground all recommendations in existing codebase architecture
- Provide structured documentation for research reflection

### Non-Goals
- Training large neural networks from scratch
- Complex deep learning implementations
- External API dependencies
- Major architectural changes
- Production-ready AI systems (prototype only)

## Decisions

### Decision: Focus on Lightweight ML Models
**Rationale**: Prototype must be implementable in <2 hours without external dependencies. Decision trees, logistic regression, K-means clustering, and simple ranking algorithms fit this constraint.

**Alternatives considered**:
- Deep learning models: Too complex, require training infrastructure
- External ML APIs: Violates constraint, adds dependencies
- Complex ensemble methods: Exceeds time budget

### Decision: Use Existing Data Sources
**Rationale**: Must leverage existing CSV files (exercises.csv, treatment.csv) or Hive/Firebase stored data (PainHistory, ExerciseHistory) to avoid data collection overhead.

**Alternatives considered**:
- Synthetic data generation: Not grounded in real system
- External datasets: Not aligned with PocketPT domain
- User surveys: Exceeds time budget

### Decision: Single Prototype Focus
**Rationale**: Deep implementation of one prototype provides more value than shallow exploration of multiple opportunities. Enables proper evaluation and demonstration.

**Alternatives considered**:
- Multiple small prototypes: Spreads effort too thin
- Analysis-only approach: Lacks practical demonstration
- Full production implementation: Exceeds scope

## Risks / Trade-offs

### Risk: Prototype May Not Show Significant Improvement
**Mitigation**: Focus on demonstrable metrics (accuracy, ranking quality) even if improvement is modest. Document baseline (rule-based) performance for comparison.

### Risk: Integration Complexity
**Mitigation**: Choose prototype that enhances existing service rather than replacing core logic. Use adapter pattern to integrate ML model alongside rule-based system.

### Risk: Data Quality Issues
**Mitigation**: Validate data extraction from CSV/Hive/Firebase. Handle missing values gracefully. Document data quality assumptions.

### Trade-off: Simplicity vs. Sophistication
**Decision**: Prioritize simplicity and demonstrability over sophisticated algorithms. A simple model that works is better than a complex model that fails.

## Migration Plan

### Phase 1: Analysis (No code changes)
- Document current implementation
- Identify opportunities
- Select prototype

### Phase 2: Prototype Implementation
- Implement ML model in isolation
- Test with extracted data
- Evaluate performance

### Phase 3: Integration
- Integrate as optional enhancement
- Maintain rule-based fallback
- Add feature flag for A/B testing

### Rollback
- Prototype is additive, not replacing existing logic
- Can disable via feature flag
- Rule-based system remains functional

## Open Questions

- Which specific AI opportunity provides the best balance of feasibility and impact?
- What evaluation metrics are most meaningful for the selected prototype?
- How should the prototype integrate with existing Flutter services?
- What data preprocessing is needed for the selected dataset?
