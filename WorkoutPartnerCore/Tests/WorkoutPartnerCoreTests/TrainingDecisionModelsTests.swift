import Foundation
import Testing
@testable import WorkoutPartnerCore

struct TrainingDecisionModelsTests {
    // MARK: - TrainingDecisionType.from(_:)

    @Test func mapsEveryTrainingActionToADecisionType() {
        #expect(TrainingDecisionType.from(.increaseLoad) == .increaseLoad)
        #expect(TrainingDecisionType.from(.reduceVolume) == .decreaseVolume)
        #expect(TrainingDecisionType.from(.holdLoad) == .maintain)
        #expect(TrainingDecisionType.from(.keepPrescription) == .maintain)
        #expect(TrainingDecisionType.from(.pauseAndReplace) == .deload)
        #expect(TrainingDecisionType.from(.selectSubstitution) == .exerciseSwap)
    }

    // MARK: - TrainingDecision.confidenceScore

    @Test func confidenceScoreReflectsEachReason() {
        func decision(_ reason: DecisionReason) -> TrainingDecision {
            TrainingDecision(action: .keepPrescription, prescription: nil, reasons: [reason], coachExplanation: "")
        }
        #expect(decision(.repeatedEasyCompletion).confidenceScore == 0.9)
        #expect(decision(.severePainReported).confidenceScore == 0.8)
        #expect(decision(.noComparableHistory).confidenceScore == 0.3)
        #expect(decision(.performanceOnTarget).confidenceScore == 0.6)
    }

    @Test func confidenceScoreWithNoReasonsDefaultsToMedium() {
        let decision = TrainingDecision(action: .keepPrescription, prescription: nil, reasons: [], coachExplanation: "")
        #expect(decision.confidenceScore == 0.6)
    }

    // MARK: - Analytics fixtures

    private func makeLog(
        decisionType: TrainingDecisionType,
        previousWeight: Double? = 60,
        newWeight: Double? = 60,
        sets: Int = 3,
        newSets: Int = 3,
        averageRPE: Double = 7,
        confidence: Double = 0.8,
        recordedAt: Date = .now
    ) -> TrainingDecisionLog {
        TrainingDecisionLog(
            sessionID: UUID(),
            exerciseID: "barbell_bench_press",
            exerciseName: "Barbell bench press",
            decisionType: decisionType,
            previousWeightKilograms: previousWeight,
            newWeightKilograms: newWeight,
            previousReps: 8,
            newReps: 8,
            previousSets: sets,
            newSets: newSets,
            averageRPE: averageRPE,
            completionRate: 1.0,
            fatigueScore: 0.5,
            confidence: confidence,
            reasoning: "test",
            adaptationVersion: 1,
            notes: "",
            recordedAt: recordedAt
        )
    }

    @Test func numberOfProgressionsCountsIncreaseLoadAndVolume() {
        let logs = [
            makeLog(decisionType: .increaseLoad),
            makeLog(decisionType: .increaseVolume),
            makeLog(decisionType: .maintain),
            makeLog(decisionType: .deload)
        ]
        #expect(numberOfProgressions(logs) == 2)
    }

    @Test func numberOfProgressionsOnEmptyHistoryIsZero() {
        #expect(numberOfProgressions([]) == 0)
    }

    @Test func numberOfDeloadsCountsDeloadAndDecreases() {
        let logs = [
            makeLog(decisionType: .deload),
            makeLog(decisionType: .decreaseLoad),
            makeLog(decisionType: .decreaseVolume),
            makeLog(decisionType: .increaseLoad)
        ]
        #expect(numberOfDeloads(logs) == 3)
    }

    @Test func averageIncreaseOnlyAveragesIncreaseLoadEntries() {
        let logs = [
            makeLog(decisionType: .increaseLoad, previousWeight: 60, newWeight: 62.5),
            makeLog(decisionType: .increaseLoad, previousWeight: 100, newWeight: 102.5),
            makeLog(decisionType: .maintain, previousWeight: 60, newWeight: 60)
        ]
        #expect(averageIncrease(logs) == 2.5)
    }

    @Test func averageIncreaseOnEmptyHistoryIsZero() {
        #expect(averageIncrease([]) == 0)
    }

    @Test func averageRPEAveragesAcrossAllEntries() {
        let logs = [
            makeLog(decisionType: .maintain, averageRPE: 6),
            makeLog(decisionType: .maintain, averageRPE: 8)
        ]
        #expect(averageRPE(logs) == 7)
    }

    @Test func adaptationFrequencyIsZeroWithFewerThanTwoEntries() {
        #expect(adaptationFrequency([]) == 0)
        #expect(adaptationFrequency([makeLog(decisionType: .maintain)]) == 0)
    }

    @Test func adaptationFrequencyCountsDecisionsPerWeek() {
        let now = Date.now
        let logs = [
            makeLog(decisionType: .maintain, recordedAt: now.addingTimeInterval(-14 * 24 * 60 * 60)),
            makeLog(decisionType: .maintain, recordedAt: now)
        ]
        // Two decisions spanning exactly two weeks -> 1 decision/week.
        #expect(adaptationFrequency(logs) == 1)
    }

    @Test func decisionSummarySummarizesCounts() {
        let logs = [
            makeLog(decisionType: .increaseLoad, confidence: 1.0),
            makeLog(decisionType: .exerciseSwap, confidence: 0.5),
            makeLog(decisionType: .deload, confidence: 0.5)
        ]
        let summary = DecisionSummary.summarizing(logs)
        #expect(summary.progressions == 1)
        #expect(summary.deloadsOrHolds == 1)
        #expect(summary.substitutions == 1)
        #expect(summary.total == 3)
        #expect(summary.averageConfidence == (1.0 + 0.5 + 0.5) / 3)
    }

    @Test func decisionSummaryOnEmptyHistoryHasZeroedFields() {
        let summary = DecisionSummary.summarizing([])
        #expect(summary.total == 0)
        #expect(summary.averageConfidence == 0)
    }
}
