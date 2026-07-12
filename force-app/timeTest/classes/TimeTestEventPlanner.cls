public with sharing class TimeTestEventPlanner {
    public static List<TimeTestEventRequest> orderByStart(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> ordered = new List<TimeTestEventRequest>();
        if (requests == null) {
            return ordered;
        }

        for (TimeTestEventRequest request : requests) {
            if (request != null) {
                ordered.add(TimeTestEventRuleEngine.normalize(request));
            }
        }

        ordered.sort(new TimeStartComparator());
        return ordered;
    }

    public static List<TimeTestEventRequest> dedupeByFingerprint(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> deduped = new List<TimeTestEventRequest>();
        if (requests == null) {
            return deduped;
        }

        Set<String> seen = new Set<String>();
        for (TimeTestEventRequest request : requests) {
            if (request == null) {
                continue;
            }
            TimeTestEventRequest normalized = TimeTestEventRuleEngine.normalize(request);
            String fingerprint = normalized.fingerprint();
            if (!seen.contains(fingerprint)) {
                seen.add(fingerprint);
                deduped.add(normalized);
            }
        }
        return deduped;
    }

    public static List<TimeTestEventSummary> buildDailySummaries(List<TimeTestEventRequest> requests) {
        List<TimeTestEventSummary> summaries = new List<TimeTestEventSummary>();
        if (requests == null) {
            return summaries;
        }

        for (TimeTestEventRequest request : orderByStart(requests)) {
            TimeTestEventSummary summary = TimeTestEventSummary.fromRequest(request);
            if (request.startDateTime != null) {
                summary.dayLabel = String.valueOf(request.startDateTime.date());
            }
            summaries.add(summary);
        }
        return summaries;
    }

    public static List<TimeTestEventSummary> buildWeekSummaries(List<TimeTestEventRequest> requests, Date weekStart) {
        List<TimeTestEventSummary> summaries = new List<TimeTestEventSummary>();
        if (requests == null || weekStart == null) {
            return summaries;
        }

        Date weekEnd = weekStart.addDays(6);
        for (TimeTestEventRequest request : orderByStart(requests)) {
            if (request == null || request.startDateTime == null) {
                continue;
            }
            Date requestDay = request.startDateTime.date();
            if (requestDay < weekStart || requestDay > weekEnd) {
                continue;
            }
            summaries.add(TimeTestEventSummary.fromRequest(request));
        }
        return summaries;
    }

    public static Map<String, Decimal> totalsByDay(List<TimeTestEventSummary> summaries) {
        Map<String, Decimal> totals = new Map<String, Decimal>();
        if (summaries == null) {
            return totals;
        }

        for (TimeTestEventSummary summary : summaries) {
            if (summary == null) {
                continue;
            }
            String key = summary.dayKey();
            Decimal current = totals.containsKey(key) ? totals.get(key) : 0;
            totals.put(key, current + summary.durationHours);
        }
        return totals;
    }

    public static Integer totalMinutes(List<TimeTestEventSummary> summaries) {
        Integer total = 0;
        if (summaries == null) {
            return total;
        }
        for (TimeTestEventSummary summary : summaries) {
            if (summary != null && summary.durationMinutes != null) {
                total += summary.durationMinutes;
            }
        }
        return total;
    }

    public static Decimal totalHours(List<TimeTestEventSummary> summaries) {
        return TimeTestEventRuleEngine.calculateHours(totalMinutes(summaries));
    }

    public static TimeTestEventRequest mergeRequests(TimeTestEventRequest left, TimeTestEventRequest right) {
        if (left == null) {
            return right == null ? null : right.copy();
        }
        if (right == null) {
            return left.copy();
        }

        TimeTestEventRequest merged = left.copy();
        if (merged.ownerId == null) {
            merged.ownerId = right.ownerId;
        }
        if (String.isBlank(merged.subject)) {
            merged.subject = right.subject;
        }
        if (String.isBlank(merged.description)) {
            merged.description = right.description;
        }
        if (String.isBlank(merged.location)) {
            merged.location = right.location;
        }
        if (
            merged.startDateTime == null || (right.startDateTime != null && right.startDateTime < merged.startDateTime)
        ) {
            merged.startDateTime = right.startDateTime;
        }
        if (merged.endDateTime == null || (right.endDateTime != null && right.endDateTime > merged.endDateTime)) {
            merged.endDateTime = right.endDateTime;
        }
        merged.allDay = merged.allDay == true || right.allDay == true;
        if (String.isBlank(merged.showAs)) {
            merged.showAs = right.showAs;
        }
        return TimeTestEventRuleEngine.normalize(merged);
    }

    public static List<TimeTestEventRequest> applyCategory(List<TimeTestEventRequest> requests, String category) {
        List<TimeTestEventRequest> updated = new List<TimeTestEventRequest>();
        if (requests == null) {
            return updated;
        }

        for (TimeTestEventRequest request : requests) {
            if (request == null) {
                continue;
            }
            TimeTestEventRequest copyRequest = request.copy();
            if (!String.isBlank(category)) {
                copyRequest.category = category.trim();
            }
            updated.add(copyRequest);
        }
        return updated;
    }

    public static List<String> findConflicts(List<TimeTestEventRequest> requests) {
        List<String> conflicts = new List<String>();
        List<TimeTestEventRequest> ordered = orderByStart(requests);
        if (ordered.size() < 2) {
            return conflicts;
        }

        for (Integer i = 0; i < ordered.size() - 1; i++) {
            TimeTestEventRequest left = ordered[i];
            TimeTestEventRequest right = ordered[i + 1];
            if (left.endDateTime != null && right.startDateTime != null && right.startDateTime < left.endDateTime) {
                conflicts.add(left.toDebugLabel() + ' overlaps ' + right.toDebugLabel());
            }
        }
        return conflicts;
    }

    public static String buildSummaryLabel(TimeTestEventRequest request) {
        TimeTestEventRequest normalized = TimeTestEventRuleEngine.normalize(request);
        if (normalized == null) {
            return 'No time entry';
        }
        List<String> parts = new List<String>();
        parts.add(String.isBlank(normalized.subject) ? 'Time entry' : normalized.subject);
        parts.add(normalized.category);
        parts.add(normalized.requestedMinutes() + 'm');
        if (normalized.startDateTime != null) {
            parts.add(String.valueOf(normalized.startDateTime.format()));
        }
        return String.join(parts, ' | ');
    }

    public static List<TimeTestEventRequest> splitLongEntries(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> result = new List<TimeTestEventRequest>();
        if (requests == null) {
            return result;
        }
        for (TimeTestEventRequest request : requests) {
            if (request == null) {
                continue;
            }
            result.addAll(TimeTestEventRuleEngine.splitAcrossDays(request));
        }
        return result;
    }

    public static List<TimeTestEventSummary> buildOverview(List<TimeTestEventRequest> requests) {
        List<TimeTestEventRequest> normalized = dedupeByFingerprint(splitLongEntries(requests));
        return buildDailySummaries(normalized);
    }

    private class TimeStartComparator implements Comparator<TimeTestEventRequest> {
        public Integer compare(TimeTestEventRequest left, TimeTestEventRequest right) {
            if (left == null && right == null) {
                return 0;
            }
            if (left == null) {
                return 1;
            }
            if (right == null) {
                return -1;
            }
            if (left.startDateTime == null && right.startDateTime == null) {
                return 0;
            }
            if (left.startDateTime == null) {
                return 1;
            }
            if (right.startDateTime == null) {
                return -1;
            }
            if (left.startDateTime == right.startDateTime) {
                String leftSubject = String.isBlank(left.subject) ? '' : left.subject;
                String rightSubject = String.isBlank(right.subject) ? '' : right.subject;
                return leftSubject.toLowerCase().compareTo(rightSubject.toLowerCase());
            }
            return left.startDateTime < right.startDateTime ? -1 : 1;
        }
    }
}
