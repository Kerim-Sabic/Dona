import 'package:flutter_test/flutter_test.dart';
import 'package:dona/domain/autopilot/autopilot_models.dart';

/// Unit tests for Autopilot Models - Plan & Action Management
void main() {
  group('AutopilotPlan - Progress Tracking', () {
    test('Empty plan has zero progress', () {
      final plan = AutopilotPlan(
        id: 'plan-1',
        intentId: 'intent-1',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [],
        status: AutopilotPlanStatus.draft,
        createdAt: DateTime.now(),
      );

      expect(plan.progress, equals(0.0));
      expect(plan.isComplete, isFalse);
    });

    test('Plan with all completed actions has full progress', () {
      final now = DateTime.now();

      final actions = List.generate(
        5,
        (i) => AutopilotAction(
          id: 'action-$i',
          actionType: 'test_action',
          description: 'Action $i',
          parameters: {},
          status: AutopilotActionStatus.completed,
          stepNumber: i + 1,
        ),
      );

      final plan = AutopilotPlan(
        id: 'plan-2',
        intentId: 'intent-2',
        planName: 'Test Plan',
        description: 'Test description',
        actions: actions,
        status: AutopilotPlanStatus.completed,
        createdAt: now,
        completedAt: now,
      );

      expect(plan.progress, equals(1.0));
      expect(plan.isComplete, isTrue);
    });

    test('Plan with partial completion shows correct progress', () {
      final actions = [
        AutopilotAction(
          id: 'action-1',
          actionType: 'test',
          description: 'Action 1',
          parameters: {},
          status: AutopilotActionStatus.completed,
          stepNumber: 1,
        ),
        AutopilotAction(
          id: 'action-2',
          actionType: 'test',
          description: 'Action 2',
          parameters: {},
          status: AutopilotActionStatus.completed,
          stepNumber: 2,
        ),
        AutopilotAction(
          id: 'action-3',
          actionType: 'test',
          description: 'Action 3',
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: 3,
        ),
        AutopilotAction(
          id: 'action-4',
          actionType: 'test',
          description: 'Action 4',
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: 4,
        ),
      ];

      final plan = AutopilotPlan(
        id: 'plan-3',
        intentId: 'intent-3',
        planName: 'Test Plan',
        description: 'Test description',
        actions: actions,
        status: AutopilotPlanStatus.inProgress,
        createdAt: DateTime.now(),
      );

      expect(plan.progress, equals(0.5)); // 2 of 4 completed
      expect(plan.isComplete, isFalse);
    });

    test('Current action is the first in-progress action', () {
      final actions = [
        AutopilotAction(
          id: 'action-1',
          actionType: 'test',
          description: 'Action 1',
          parameters: {},
          status: AutopilotActionStatus.completed,
          stepNumber: 1,
        ),
        AutopilotAction(
          id: 'action-2',
          actionType: 'test',
          description: 'Action 2',
          parameters: {},
          status: AutopilotActionStatus.inProgress,
          stepNumber: 2,
        ),
        AutopilotAction(
          id: 'action-3',
          actionType: 'test',
          description: 'Action 3',
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: 3,
        ),
      ];

      final plan = AutopilotPlan(
        id: 'plan-4',
        intentId: 'intent-4',
        planName: 'Test Plan',
        description: 'Test description',
        actions: actions,
        status: AutopilotPlanStatus.inProgress,
        createdAt: DateTime.now(),
      );

      expect(plan.currentAction, isNotNull);
      expect(plan.currentAction!.stepNumber, equals(2));
      expect(plan.currentAction!.status, equals(AutopilotActionStatus.inProgress));
    });

    test('Current action is first pending if none in progress', () {
      final actions = [
        AutopilotAction(
          id: 'action-1',
          actionType: 'test',
          description: 'Action 1',
          parameters: {},
          status: AutopilotActionStatus.completed,
          stepNumber: 1,
        ),
        AutopilotAction(
          id: 'action-2',
          actionType: 'test',
          description: 'Action 2',
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: 2,
        ),
        AutopilotAction(
          id: 'action-3',
          actionType: 'test',
          description: 'Action 3',
          parameters: {},
          status: AutopilotActionStatus.pending,
          stepNumber: 3,
        ),
      ];

      final plan = AutopilotPlan(
        id: 'plan-5',
        intentId: 'intent-5',
        planName: 'Test Plan',
        description: 'Test description',
        actions: actions,
        status: AutopilotPlanStatus.pendingApproval,
        createdAt: DateTime.now(),
      );

      expect(plan.currentAction, isNotNull);
      expect(plan.currentAction!.stepNumber, equals(2)); // First pending
    });
  });

  group('AutopilotPlan - Status Management', () {
    test('Completed status marks plan as complete', () {
      final plan = AutopilotPlan(
        id: 'plan-6',
        intentId: 'intent-6',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [],
        status: AutopilotPlanStatus.completed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(plan.isComplete, isTrue);
    });

    test('Failed status marks plan as complete', () {
      final plan = AutopilotPlan(
        id: 'plan-7',
        intentId: 'intent-7',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [],
        status: AutopilotPlanStatus.failed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        failureReason: 'Network error',
      );

      expect(plan.isComplete, isTrue);
      expect(plan.failureReason, isNotNull);
    });

    test('Cancelled status marks plan as complete', () {
      final plan = AutopilotPlan(
        id: 'plan-8',
        intentId: 'intent-8',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [],
        status: AutopilotPlanStatus.cancelled,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(plan.isComplete, isTrue);
    });

    test('In-progress status does not mark plan as complete', () {
      final plan = AutopilotPlan(
        id: 'plan-9',
        intentId: 'intent-9',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [],
        status: AutopilotPlanStatus.inProgress,
        createdAt: DateTime.now(),
        startedAt: DateTime.now(),
      );

      expect(plan.isComplete, isFalse);
    });
  });

  group('AutopilotAction - Status Transitions', () {
    test('Action copyWith updates status', () {
      final action = AutopilotAction(
        id: 'action-1',
        actionType: AutopilotActionType.createEvent,
        description: 'Create calendar event',
        parameters: {'title': 'Meeting'},
        status: AutopilotActionStatus.pending,
        stepNumber: 1,
      );

      final inProgress = action.copyWith(
        status: AutopilotActionStatus.inProgress,
      );

      expect(inProgress.status, equals(AutopilotActionStatus.inProgress));
      expect(inProgress.id, equals(action.id)); // Unchanged
      expect(inProgress.description, equals(action.description)); // Unchanged
    });

    test('Action copyWith updates execution result', () {
      final action = AutopilotAction(
        id: 'action-2',
        actionType: AutopilotActionType.createTask,
        description: 'Create task',
        parameters: {'title': 'Review code'},
        status: AutopilotActionStatus.inProgress,
        stepNumber: 1,
      );

      final now = DateTime.now();
      final completed = action.copyWith(
        status: AutopilotActionStatus.completed,
        executedAt: now,
        resultMessage: 'Task created successfully',
      );

      expect(completed.status, equals(AutopilotActionStatus.completed));
      expect(completed.executedAt, equals(now));
      expect(completed.resultMessage, equals('Task created successfully'));
    });

    test('Action with requiresApproval flag', () {
      final criticalAction = AutopilotAction(
        id: 'action-3',
        actionType: AutopilotActionType.sendEmail,
        description: 'Send email to boss',
        parameters: {},
        status: AutopilotActionStatus.pending,
        requiresApproval: true,
        stepNumber: 1,
      );

      expect(criticalAction.requiresApproval, isTrue);

      final automatedAction = AutopilotAction(
        id: 'action-4',
        actionType: AutopilotActionType.setReminder,
        description: 'Set reminder',
        parameters: {},
        status: AutopilotActionStatus.pending,
        requiresApproval: false,
        stepNumber: 2,
      );

      expect(automatedAction.requiresApproval, isFalse);
    });
  });

  group('AutopilotResult - Success Tracking', () {
    test('Successful result with all actions completed', () {
      final result = AutopilotResult(
        planId: 'plan-1',
        success: true,
        summary: 'All 5 actions completed successfully',
        completedActions: [
          'Create calendar event',
          'Create task',
          'Set reminder',
          'Send email',
          'Create note',
        ],
        failedActions: [],
        timestamp: DateTime.now(),
      );

      expect(result.success, isTrue);
      expect(result.completedActions.length, equals(5));
      expect(result.failedActions, isEmpty);
    });

    test('Failed result with some failures', () {
      final result = AutopilotResult(
        planId: 'plan-2',
        success: false,
        summary: 'Completed 3 actions, 2 failed',
        completedActions: [
          'Create calendar event',
          'Create task',
          'Set reminder',
        ],
        failedActions: [
          'Send email',
          'Create note',
        ],
        metadata: {'errorCode': 'network_error'},
        timestamp: DateTime.now(),
      );

      expect(result.success, isFalse);
      expect(result.completedActions.length, equals(3));
      expect(result.failedActions.length, equals(2));
      expect(result.metadata, containsPair('errorCode', 'network_error'));
    });
  });

  group('Autopilot - JSON Serialization', () {
    test('AutopilotPlan serializes to JSON', () {
      final now = DateTime.now();

      final plan = AutopilotPlan(
        id: 'plan-1',
        intentId: 'intent-1',
        planName: 'Test Plan',
        description: 'Test description',
        actions: [
          AutopilotAction(
            id: 'action-1',
            actionType: 'test',
            description: 'Action 1',
            parameters: {},
            status: AutopilotActionStatus.pending,
            stepNumber: 1,
          ),
        ],
        status: AutopilotPlanStatus.draft,
        createdAt: now,
      );

      final json = plan.toMap();

      expect(json['id'], equals('plan-1'));
      expect(json['planName'], equals('Test Plan'));
      expect(json['status'], equals('draft'));
      expect(json['actions'], isA<List>());
    });

    test('AutopilotPlan deserializes from JSON', () {
      final now = DateTime.now();

      final json = {
        'id': 'plan-2',
        'intentId': 'intent-2',
        'planName': 'Deserialized Plan',
        'description': 'From JSON',
        'actions': [
          {
            'id': 'action-1',
            'actionType': 'test',
            'description': 'Test action',
            'parameters': {},
            'status': 'pending',
            'requiresApproval': true,
            'stepNumber': 1,
          },
        ],
        'status': 'draft',
        'createdAt': now.millisecondsSinceEpoch,
      };

      final plan = AutopilotPlan.fromMap(json);

      expect(plan.id, equals('plan-2'));
      expect(plan.planName, equals('Deserialized Plan'));
      expect(plan.actions.length, equals(1));
      expect(plan.status, equals(AutopilotPlanStatus.draft));
    });
  });
}
