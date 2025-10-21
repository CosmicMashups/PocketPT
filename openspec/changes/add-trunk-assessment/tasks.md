## 1. Implementation
- [ ] 1.1 Create comprehensive b_trunk_assessment.dart module with unified logic
- [ ] 1.2 Implement trunk angle calculation using shoulder-hip-knee landmarks
- [ ] 1.3 Add muscle type parameter support for all four trunk muscle groups
- [ ] 1.4 Implement pain level classification based on trunk flexion/extension angles
- [ ] 1.5 Add error handling for missing landmarks and edge cases

## 2. Integration
- [ ] 2.1 Update assessment_service.dart to route all trunk muscle groups to unified module
- [ ] 2.2 Add trunk clinical thresholds to assessment_constants.dart
- [ ] 2.3 Ensure compatibility with existing pose detection service
- [ ] 2.4 Verify integration with camera assessment UI

## 3. Testing & Validation
- [ ] 3.1 Test trunk assessment with various pose angles (severe, moderate, low pain scenarios)
- [ ] 3.2 Validate error handling for missing landmarks
- [ ] 3.3 Verify pain scale mapping consistency with existing assessments
- [ ] 3.4 Test real-time assessment integration with camera pipeline
- [ ] 3.5 Validate OpenSpec proposal compliance