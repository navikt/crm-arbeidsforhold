public with sharing class TimeTestEventController {
    @AuraEnabled(cacheable=true)
    public static List<TimeTestEventSummary> previewWeek(List<TimeTestEventRequest> requests, Date weekStart) {
        return TimeTestEventPlanner.buildWeekSummaries(requests, weekStart);
    }

    @AuraEnabled(cacheable=true)
    public static List<TimeTestEventSummary> previewAll(List<TimeTestEventRequest> requests) {
        return TimeTestEventPlanner.buildOverview(requests);
    }

    @AuraEnabled
    public static List<String> validateRequests(List<TimeTestEventRequest> requests) {
        List<String> errors = new List<String>();
        if (requests == null) {
            errors.add('Requests are required.');
            return errors;
        }

        for (TimeTestEventRequest request : requests) {
            errors.addAll(TimeTestEventRuleEngine.validate(request));
        }
        return errors;
    }

    @AuraEnabled
    public static List<TimeTestEventRequest> normalizeRequests(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> normalized = new List<TimeTestEventRequest>();
        if (requests == null) {
            return normalized;
        }

        for (TimeTestEventRequest request : requests) {
            if (request != null) {
                normalized.add(TimeTestEventRuleEngine.normalize(request));
            }
        }
        return normalized;
    }

    @AuraEnabled
    public static List<TimeTestEventRequest> splitRequest(TimeTestEventRequest request) {
        return TimeTestEventRuleEngine.splitAcrossDays(request);
    }

    @AuraEnabled
    public static TimeTestEventSummary previewSummary(TimeTestEventRequest request) {
        return TimeTestEventSummary.fromRequest(TimeTestEventRuleEngine.normalize(request));
    }

    @AuraEnabled
    public static String previewLabel(TimeTestEventRequest request) {
        return TimeTestEventPlanner.buildSummaryLabel(request);
    }

    @AuraEnabled
    public static Decimal totalHours(List<TimeTestEventRequest> requests) {
        return TimeTestEventPlanner.totalHours(TimeTestEventPlanner.buildOverview(requests));
    }

    @AuraEnabled
    public static Map<String, Decimal> hoursByDay(List<TimeTestEventRequest> requests) {
        return TimeTestEventPlanner.totalsByDay(TimeTestEventPlanner.buildOverview(requests));
    }

    @AuraEnabled
    public static List<String> findConflicts(List<TimeTestEventRequest> requests) {
        return TimeTestEventPlanner.findConflicts(requests);
    }

    @AuraEnabled
    public static Boolean canAutoClose(TimeTestEventRequest request) {
        return TimeTestEventRuleEngine.canAutoClose(request);
    }

    @AuraEnabled
    public static List<TimeTestEventRequest> shiftToNextWorkingDay(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> shifted = new List<TimeTestEventRequest>();
        if (requests == null) {
            return shifted;
        }
        for (TimeTestEventRequest request : requests) {
            if (request != null) {
                shifted.add(TimeTestEventRuleEngine.shiftToNextWorkingDay(request));
            }
        }
        return shifted;
    }
}
