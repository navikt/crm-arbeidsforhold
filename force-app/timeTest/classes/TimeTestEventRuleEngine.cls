public with sharing class TimeTestEventRuleEngine {
    private static final Integer DEFAULT_DURATION_MINUTES = 60;
    private static final Integer MAX_DURATION_MINUTES = 24 * 60;
    private static final String DEFAULT_SHOW_AS = 'Busy';
    private static final Set<String> VALID_SHOW_AS = new Set<String>{ 'Busy', 'Free', 'Out of Office' };

    public static TimeTestEventRequest normalize(TimeTestEventRequest request) {
        if (request == null) {
            return null;
        }

        TimeTestEventRequest normalized = request.copy();
        normalized.trimStrings();
        normalized.ensureDefaults();

        if (normalized.startDateTime == null && normalized.endDateTime != null) {
            normalized.startDateTime = normalized.endDateTime.addMinutes(-DEFAULT_DURATION_MINUTES);
        }

        if (normalized.startDateTime != null && normalized.endDateTime == null) {
            normalized.endDateTime = normalized.startDateTime.addMinutes(DEFAULT_DURATION_MINUTES);
        }

        if (normalized.allDay == true && normalized.startDateTime != null) {
            normalized.startDateTime = Datetime.newInstance(
                normalized.startDateTime.date(),
                Time.newInstance(0, 0, 0, 0)
            );
        }
        if (normalized.allDay == true && normalized.endDateTime != null) {
            normalized.endDateTime = Datetime.newInstance(
                normalized.endDateTime.date(),
                Time.newInstance(23, 59, 59, 999)
            );
        }

        if (String.isBlank(normalized.showAs)) {
            normalized.showAs = DEFAULT_SHOW_AS;
        }

        return normalized;
    }

    public static void ensureValid(TimeTestEventRequest request) {
        List<String> errors = validate(request);
        if (!errors.isEmpty()) {
            throw new AuraHandledException(String.join(errors, ' | '));
        }
    }

    public static List<String> validate(TimeTestEventRequest request) {
        List<String> errors = new List<String>();
        if (request == null) {
            errors.add('Request is required.');
            return errors;
        }

        if (String.isBlank(request.subject)) {
            errors.add('Subject is required.');
        }
        if (request.ownerId == null) {
            errors.add('Owner is required.');
        }
        if (request.startDateTime == null) {
            errors.add('Start date/time is required.');
        }
        if (request.endDateTime == null) {
            errors.add('End date/time is required.');
        }
        if (
            request.startDateTime != null &&
            request.endDateTime != null &&
            request.endDateTime <= request.startDateTime
        ) {
            errors.add('End must be after start.');
        }
        if (request.requestedMinutes() > MAX_DURATION_MINUTES) {
            errors.add('Time entry cannot exceed 24 hours.');
        }
        if (
            request.allDay == true &&
            request.hasWindow() &&
            request.startDateTime.date() != request.endDateTime.date()
        ) {
            errors.add('All-day entries must stay on one day.');
        }
        if (!String.isBlank(request.showAs) && !VALID_SHOW_AS.contains(request.showAs)) {
            errors.add('Invalid showAs value.');
        }
        if (request.locked == true && request.requestedMinutes() > 0) {
            errors.add('Locked entries cannot be modified.');
        }
        return errors;
    }

    public static Boolean canAutoClose(TimeTestEventRequest request) {
        TimeTestEventRequest normalized = normalize(request);
        if (normalized == null) {
            return false;
        }
        if (!normalized.hasMeaningfulText()) {
            return false;
        }
        return normalized.requestedMinutes() > 0 && normalized.locked != true;
    }

    public static Integer calculateMinutes(Datetime startValue, Datetime endValue, Boolean allDay) {
        if (startValue == null || endValue == null) {
            return 0;
        }
        if (endValue <= startValue) {
            return 0;
        }
        if (allDay == true) {
            return MAX_DURATION_MINUTES;
        }
        Long millis = endValue.getTime() - startValue.getTime();
        if (millis <= 0) {
            return 0;
        }
        return Integer.valueOf(millis / 60000);
    }

    public static Decimal calculateHours(Integer minutes) {
        if (minutes == null || minutes <= 0) {
            return 0;
        }
        return Decimal.valueOf(minutes) / 60;
    }

    public static Boolean isWeekend(Date dayValue) {
        if (dayValue == null) {
            return false;
        }
        Integer daysSinceEpoch = Date.newInstance(1970, 1, 1).daysBetween(dayValue);
        Integer dayOfWeek = Math.mod(daysSinceEpoch + 4, 7);
        return dayOfWeek == 0 || dayOfWeek == 6;
    }

    public static Date nextWorkingDay(Date dayValue) {
        if (dayValue == null) {
            return null;
        }
        Date candidate = dayValue.addDays(1);
        while (isWeekend(candidate)) {
            candidate = candidate.addDays(1);
        }
        return candidate;
    }

    public static TimeTestEventRequest clampToWorkingHours(TimeTestEventRequest request, Time startTime, Time endTime) {
        if (request == null) {
            return null;
        }

        TimeTestEventRequest clamped = normalize(request);
        if (clamped == null || clamped.startDateTime == null || clamped.endDateTime == null) {
            return clamped;
        }

        Time workingStart = startTime == null ? Time.newInstance(8, 0, 0, 0) : startTime;
        Time workingEnd = endTime == null ? Time.newInstance(16, 0, 0, 0) : endTime;

        Datetime startBoundary = Datetime.newInstance(clamped.startDateTime.date(), workingStart);
        Datetime endBoundary = Datetime.newInstance(clamped.endDateTime.date(), workingEnd);

        if (clamped.startDateTime < startBoundary) {
            clamped.startDateTime = startBoundary;
        }
        if (clamped.endDateTime > endBoundary) {
            clamped.endDateTime = endBoundary;
        }
        if (clamped.endDateTime <= clamped.startDateTime) {
            clamped.endDateTime = clamped.startDateTime.addMinutes(DEFAULT_DURATION_MINUTES);
        }
        return clamped;
    }

    public static List<TimeTestEventRequest> splitAcrossDays(TimeTestEventRequest request) {
        if (request == null) {
            return new List<TimeTestEventRequest>();
        }

        TimeTestEventRequest normalized = normalize(request);
        if (normalized == null || !normalized.hasWindow()) {
            return new List<TimeTestEventRequest>();
        }
        if (normalized.startDateTime.date() == normalized.endDateTime.date()) {
            return new List<TimeTestEventRequest>{ normalized };
        }

        List<TimeTestEventRequest> slices = new List<TimeTestEventRequest>();
        Datetime currentSliceStart = normalized.startDateTime;
        while (currentSliceStart.date() < normalized.endDateTime.date()) {
            Datetime currentEndOfDay = Datetime.newInstance(
                currentSliceStart.date(),
                Time.newInstance(23, 59, 59, 999)
            );
            slices.add(normalized.withWindow(currentSliceStart, currentEndOfDay));
            currentSliceStart = Datetime.newInstance(currentSliceStart.date().addDays(1), Time.newInstance(0, 0, 0, 0));
        }
        slices.add(normalized.withWindow(currentSliceStart, normalized.endDateTime));
        return slices;
    }

    public static Map<String, Object> toValidationMap(TimeTestEventRequest request) {
        Map<String, Object> data = new Map<String, Object>();
        TimeTestEventRequest normalized = normalize(request);
        data.put('subject', normalized == null ? null : normalized.subject);
        data.put('ownerId', normalized == null ? null : normalized.ownerId);
        data.put('minutes', normalized == null ? 0 : normalized.requestedMinutes());
        data.put('canAutoClose', canAutoClose(request));
        data.put(
            'isWeekendStart',
            normalized != null && normalized.startDateTime != null && isWeekend(normalized.startDateTime.date())
        );
        return data;
    }

    public static String firstValidationMessage(TimeTestEventRequest request) {
        List<String> errors = validate(request);
        return errors.isEmpty() ? null : errors[0];
    }

    public static TimeTestEventRequest shiftToNextWorkingDay(TimeTestEventRequest request) {
        if (request == null) {
            return null;
        }
        TimeTestEventRequest shifted = normalize(request);
        if (shifted == null || shifted.startDateTime == null || shifted.endDateTime == null) {
            return shifted;
        }
        Date nextDay = nextWorkingDay(shifted.startDateTime.date());
        if (nextDay == null) {
            return shifted;
        }
        Time startTime = shifted.startDateTime.time();
        Time endTime = shifted.endDateTime.time();
        shifted.startDateTime = Datetime.newInstance(nextDay, startTime);
        shifted.endDateTime = Datetime.newInstance(nextDay, endTime);
        return shifted;
    }
}
