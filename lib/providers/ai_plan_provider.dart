import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_plan_model.dart';
import '../models/planner_preferences_model.dart';
import '../models/task_model.dart';
import '../providers/user_provider.dart';
import '../services/ai_plan_service.dart';
import '../services/ai_recommendation_service.dart';
import '../services/groq_ai_plan_service.dart';

final aiPlanServiceProvider = Provider<AIPlanService>((ref) => AIPlanService());

final aiRecommendationServiceProvider = Provider<AIRecommendationService>(
  (ref) => AIRecommendationService(),
);

final groqAIPlanServiceProvider = Provider<GroqAIPlanService>(
  (ref) => GroqAIPlanService(),
);

final aiPlanProvider = StreamProvider<List<AIPlanModel>>((ref) {
  final uid = ref.watch(userProvider.select((user) => user?.uid));

  if (uid == null) {
    return const Stream.empty();
  }

  return ref.read(aiPlanServiceProvider).getPlans(uid);
});

class AIPlanNotifier extends Notifier<void> {
  late final AIPlanService _planService;
  late final AIRecommendationService _recommendationService;
  late final GroqAIPlanService _groqService;

  @override
  void build() {
    _planService = ref.read(aiPlanServiceProvider);
    _recommendationService = ref.read(aiRecommendationServiceProvider);
    _groqService = ref.read(groqAIPlanServiceProvider);
  }

  Future<void> addPlan(AIPlanModel plan) => _planService.addPlan(plan);

  Future<void> updatePlan(AIPlanModel plan) => _planService.updatePlan(plan);

  Future<void> deletePlan(String id) => _planService.deletePlan(id);

  Future<void> addOrUpdatePlan(AIPlanModel plan) =>
      _planService.addOrUpdatePlan(plan);

  Future<bool> generatePlans({
    required List<TaskModel> tasks,
    required List<StudySlot> studySlots,
    required FocusPreference preference,
    required double confidence,
    required String notes,
    required String userId,
    required List<AIPlanModel> existingPlans,
    required bool isPremium,
    required Future<void> Function() increaseAiUsage,
  }) async {
    await _planService.deleteAllPlans(userId);

    List<AIPlanModel> plans;
    bool usedAI = true;
    try {
      // Ask a real LLM (Groq) to read the tasks/availability/preferences
      // and decide what to study and when.
      plans = await _groqService.generatePlans(
        tasks: tasks,
        studySlots: studySlots,
        preference: preference,
        confidence: confidence,
        notes: notes,
        userId: userId,
        existingPlans: existingPlans,
      );
    } catch (e) {
      usedAI = false;
      // If the AI call fails or returns something unusable — no/invalid
      // API key, network error, malformed reply — fall back to the
      // deterministic scheduler so plan generation never just breaks.
      plans = _recommendationService.generatePlans(
        tasks: tasks,
        studySlots: studySlots,
        preference: preference,
        confidence: confidence,
        userId: userId,
        existingPlans: existingPlans,
      );
    }

    // Save the newly generated plans
    await _planService.savePlans(plans);

    // Free users consume one AI generation
    if (!isPremium) {
      await increaseAiUsage();
    }
    return usedAI;
  }
}

final aiPlanNotifierProvider = NotifierProvider<AIPlanNotifier, void>(
  AIPlanNotifier.new,
);
