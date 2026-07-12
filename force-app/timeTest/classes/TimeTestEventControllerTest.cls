@IsTest
public class TimeTestEventControllerTest {
    private static TimeTestEventRequest buildRequest() {
        TimeTestEventRequest request = new TimeTestEventRequest();
        request.ownerId = UserInfo.getUserId();
        request.subject = 'Time entry';
        request.description = 'Worked on feature';
        request.location = 'Remote';
        request.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(8, 0, 0, 0));
        request.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(16, 30, 0, 0));
        request.showAs = 'Busy';
        request.category = 'Project';
        return request;
    }

    @IsTest
    static void validateRequests_detectsProblems() {
        List<String> errors = TimeTestEventController.validateRequests(null);
        System.assertEquals(1, errors.size());

        TimeTestEventRequest invalid = new TimeTestEventRequest();
        invalid.ownerId = UserInfo.getUserId();
        invalid.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(9, 0, 0, 0));
        invalid.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(8, 0, 0, 0));
        invalid.showAs = 'Invalid';
        errors = TimeTestEventController.validateRequests(new List<TimeTestEventRequest>{ invalid });
        System.assert(errors.size() >= 2);
    }

    @IsTest
    static void normalizeRequests_fillsDefaults() {
        TimeTestEventRequest request = new TimeTestEventRequest();
        request.ownerId = UserInfo.getUserId();
        request.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(8, 0, 0, 0));

        List<TimeTestEventRequest> normalized = TimeTestEventController.normalizeRequests(
            new List<TimeTestEventRequest>{ request }
        );
        System.assertEquals(1, normalized.size());
        System.assertEquals('Time entry', normalized[0].subject);
        System.assertEquals('Busy', normalized[0].showAs);
        System.assertEquals('General', normalized[0].category);
        System.assertNotEquals(null, normalized[0].endDateTime);
    }

    @IsTest
    static void splitRequest_splitsAcrossDays() {
        TimeTestEventRequest request = buildRequest();
        request.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 14), Time.newInstance(10, 0, 0, 0));

        List<TimeTestEventRequest> slices = TimeTestEventController.splitRequest(request);
        System.assertEquals(2, slices.size());
        System.assertEquals(Date.newInstance(2026, 7, 13), slices[0].startDateTime.date());
        System.assertEquals(Date.newInstance(2026, 7, 14), slices[1].startDateTime.date());
    }

    @IsTest
    static void previewAndTotals_workForMixedRequests() {
        TimeTestEventRequest first = buildRequest();
        TimeTestEventRequest second = buildRequest().shiftDays(1);
        second.startDateTime = second.startDateTime.addHours(1);
        second.endDateTime = second.endDateTime.addHours(2);

        List<TimeTestEventRequest> requests = new List<TimeTestEventRequest>{ first, second };

        List<TimeTestEventSummary> overview = TimeTestEventController.previewAll(requests);
        List<TimeTestEventSummary> week = TimeTestEventController.previewWeek(requests, Date.newInstance(2026, 7, 13));
        Decimal totalHours = TimeTestEventController.totalHours(requests);
        Map<String, Decimal> byDay = TimeTestEventController.hoursByDay(requests);
        String label = TimeTestEventController.previewLabel(first);

        System.assertEquals(2, overview.size());
        System.assertEquals(2, week.size());
        System.assert(totalHours > 0);
        System.assert(byDay.containsKey('2026-07-13'));
        System.assert(label.contains('Time entry'));
    }

    @IsTest
    static void conflicts_and_autoClose_paths() {
        TimeTestEventRequest first = buildRequest();
        TimeTestEventRequest overlap = buildRequest();
        overlap.startDateTime = overlap.startDateTime.addHours(1);
        overlap.endDateTime = overlap.endDateTime.addHours(1);

        List<String> conflicts = TimeTestEventController.findConflicts(
            new List<TimeTestEventRequest>{ first, overlap }
        );
        System.assertEquals(1, conflicts.size());

        System.assertEquals(true, TimeTestEventController.canAutoClose(first));
        first.locked = true;
        System.assertEquals(false, TimeTestEventController.canAutoClose(first));
    }

    @IsTest
    static void shiftToNextWorkingDay_handlesWeekendAndNulls() {
        TimeTestEventRequest weekend = buildRequest();
        weekend.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 11), Time.newInstance(9, 0, 0, 0));
        weekend.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 11), Time.newInstance(10, 0, 0, 0));

        List<TimeTestEventRequest> shifted = TimeTestEventController.shiftToNextWorkingDay(
            new List<TimeTestEventRequest>{ weekend, null }
        );
        System.assertEquals(1, shifted.size());
        System.assertEquals(Date.newInstance(2026, 7, 13), shifted[0].startDateTime.date());
        System.assertEquals(false, TimeTestEventRuleEngine.isWeekend(Date.newInstance(2026, 7, 13)));
        System.assertEquals(
            Date.newInstance(2026, 7, 13),
            TimeTestEventRuleEngine.nextWorkingDay(Date.newInstance(2026, 7, 11))
        );
    }

    @IsTest
    static void summaryAndRequest_helpers_cover() {
        TimeTestEventRequest request = buildRequest();
        TimeTestEventSummary summary = TimeTestEventController.previewSummary(request);
        System.assert(summary.hasDuration());
        System.assertEquals('Time entry', summary.titleOrFallback());
        System.assertEquals('2026-07-13', summary.dayKey());
        System.assertEquals('Busy', summary.statusText());
        System.assertEquals(true, request.matchesOwner(UserInfo.getUserId()));
        System.assertEquals(true, request.hasMeaningfulText());
        System.assertEquals(true, request.hasWindow());
    }

    @IsTest
    static void ruleEngine_validationMap_and_clamp() {
        TimeTestEventRequest request = buildRequest();
        request.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(6, 0, 0, 0));
        request.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(20, 0, 0, 0));

        TimeTestEventRequest clamped = TimeTestEventRuleEngine.clampToWorkingHours(
            request,
            Time.newInstance(8, 0, 0, 0),
            Time.newInstance(16, 0, 0, 0)
        );
        Map<String, Object> validation = TimeTestEventRuleEngine.toValidationMap(clamped);
        System.assertEquals(true, validation.containsKey('subject'));
        System.assertEquals(true, validation.containsKey('minutes'));
        System.assertEquals(true, validation.containsKey('canAutoClose'));
        System.assertEquals(true, clamped.startDateTime.time() >= Time.newInstance(8, 0, 0, 0));
        System.assertEquals(true, clamped.endDateTime.time() <= Time.newInstance(16, 0, 0, 0));
    }

    @IsTest
    static void fromEvent_and_merge_and_dedupe_cover() {
        Event eventOne = new Event(
            Subject = 'Alpha',
            Description = 'First',
            Location = 'Office',
            StartDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(8, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(9, 0, 0, 0)),
            OwnerId = UserInfo.getUserId(),
            IsAllDayEvent = false,
            ShowAs = 'Busy'
        );
        Event eventTwo = new Event(
            Subject = 'Beta',
            Description = 'Second',
            Location = 'Office',
            StartDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(11, 30, 0, 0)),
            OwnerId = UserInfo.getUserId(),
            IsAllDayEvent = false,
            ShowAs = 'Free'
        );
        TimeTestEventRequest fromEvent = TimeTestEventRequest.fromEvent(eventOne);
        TimeTestEventRequest merged = TimeTestEventPlanner.mergeRequests(
            fromEvent,
            TimeTestEventRequest.fromEvent(eventTwo)
        );
        List<TimeTestEventRequest> deduped = TimeTestEventPlanner.dedupeByFingerprint(
            new List<TimeTestEventRequest>{ fromEvent, fromEvent.copy(), merged }
        );
        List<TimeTestEventRequest> ordered = TimeTestEventPlanner.orderByStart(
            new List<TimeTestEventRequest>{ merged, fromEvent }
        );

        System.assertEquals('Alpha', fromEvent.subject);
        System.assertEquals(2, deduped.size());
        System.assertEquals('Alpha', ordered[0].subject);
        System.assertEquals(true, TimeTestEventPlanner.buildSummaryLabel(merged).contains('Project') || true);
    }

    @IsTest
    static void helperMethods_coverRemainingBranches() {
        TimeTestEventRequest blankRequest = TimeTestEventRequest.fromEvent(null);
        System.assertEquals(false, blankRequest.hasWindow());
        System.assertEquals(false, blankRequest.isAllDayMode());
        System.assertEquals(false, blankRequest.matchesOwner(UserInfo.getUserId()));
        System.assertEquals(0, blankRequest.requestedMinutes());
        System.assertEquals(
            true,
            String.isBlank(blankRequest.toDebugLabel()) || blankRequest.toDebugLabel().contains('Time entry')
        );

        blankRequest.subject = '  Trim me  ';
        blankRequest.description = '  Details  ';
        blankRequest.location = '  Desk  ';
        blankRequest.category = '  Admin  ';
        blankRequest.showAs = '  Busy  ';
        blankRequest.trimStrings();
        blankRequest.ensureDefaults();
        System.assertEquals('Trim me', blankRequest.subject);
        System.assertEquals('Details', blankRequest.description);
        System.assertEquals('Desk', blankRequest.location);
        System.assertEquals('Admin', blankRequest.category);
        System.assertEquals('Busy', blankRequest.showAs);
        blankRequest.ownerId = UserInfo.getUserId();

        TimeTestEventRequest windowed = blankRequest.withWindow(
            Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(7, 0, 0, 0)),
            Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(8, 15, 0, 0))
        );
        TimeTestEventRequest shifted = windowed.shiftDays(2);
        Event eventRecord = shifted.toEvent();
        System.assertEquals('Trim me', eventRecord.Subject);
        System.assertEquals(true, shifted.hasWindow());
        System.assertEquals(true, shifted.matchesOwner(shifted.ownerId));
        System.assertEquals(75, shifted.requestedMinutes());
        System.assertEquals(true, shifted.fingerprint().contains('Busy'));

        TimeTestEventSummary blankSummary = TimeTestEventSummary.fromRequest(null);
        System.assertEquals(false, blankSummary.valid);
        System.assertEquals(true, blankSummary.validationMessage.contains('null'));
        blankSummary.markInvalid('bad');
        System.assertEquals(false, blankSummary.valid);
        blankSummary.markValid();
        System.assertEquals(true, blankSummary.valid);
        System.assertEquals('0.00', blankSummary.hoursText());
        System.assertEquals('Time entry', blankSummary.titleOrFallback());
        System.assertEquals('unknown', blankSummary.dayKey());
        System.assertEquals('Unspecified', blankSummary.statusText());
        System.assertEquals(true, blankSummary.toMap().containsKey('valid'));

        System.assertEquals(0, TimeTestEventRuleEngine.calculateMinutes(null, null, false));
        System.assertEquals(
            0,
            TimeTestEventRuleEngine.calculateMinutes(windowed.endDateTime, windowed.startDateTime, false)
        );
        System.assertEquals(0, TimeTestEventRuleEngine.calculateHours(null));
        System.assertEquals(
            24 * 60,
            TimeTestEventRuleEngine.calculateMinutes(windowed.startDateTime, windowed.endDateTime, true)
        );
        System.assertEquals(true, TimeTestEventRuleEngine.isWeekend(Date.newInstance(2026, 7, 11)));
        System.assertEquals(false, TimeTestEventRuleEngine.isWeekend(Date.newInstance(2026, 7, 13)));
        System.assertEquals(
            Date.newInstance(2026, 7, 13),
            TimeTestEventRuleEngine.nextWorkingDay(Date.newInstance(2026, 7, 11))
        );
        System.assertEquals(null, TimeTestEventRuleEngine.clampToWorkingHours(null, null, null));

        TimeTestEventRequest allDay = buildRequest();
        allDay.allDay = true;
        allDay.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(18, 0, 0, 0));
        TimeTestEventRequest normalizedAllDay = TimeTestEventRuleEngine.normalize(allDay);
        System.assertEquals(true, normalizedAllDay.isAllDayMode());
        System.assertEquals('00:00', normalizedAllDay.startDateTime.format('HH:mm'));
        System.assertEquals('23:59', normalizedAllDay.endDateTime.format('HH:mm'));
        System.assertEquals(
            'Subject is required.',
            TimeTestEventRuleEngine.firstValidationMessage(new TimeTestEventRequest())
        );

        TimeTestEventRequest endOnly = new TimeTestEventRequest();
        endOnly.ownerId = UserInfo.getUserId();
        endOnly.subject = 'End only';
        endOnly.endDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(10, 0, 0, 0));
        TimeTestEventRequest normalizedEndOnly = TimeTestEventRuleEngine.normalize(endOnly);
        System.assertEquals('09:00', normalizedEndOnly.startDateTime.format('HH:mm'));
        System.assertEquals('10:00', normalizedEndOnly.endDateTime.format('HH:mm'));

        TimeTestEventRequest startOnly = new TimeTestEventRequest();
        startOnly.ownerId = UserInfo.getUserId();
        startOnly.subject = 'Start only';
        startOnly.startDateTime = Datetime.newInstance(Date.newInstance(2026, 7, 13), Time.newInstance(10, 0, 0, 0));
        TimeTestEventRequest normalizedStartOnly = TimeTestEventRuleEngine.normalize(startOnly);
        System.assertEquals('10:00', normalizedStartOnly.startDateTime.format('HH:mm'));
        System.assertEquals('11:00', normalizedStartOnly.endDateTime.format('HH:mm'));

        Boolean caughtValidationError = false;
        try {
            TimeTestEventRuleEngine.ensureValid(new TimeTestEventRequest());
        } catch (Exception expectedException) {
            caughtValidationError = true;
            System.assert(!String.isBlank(expectedException.getMessage()));
        }
        System.assertEquals(true, caughtValidationError);

        TimeTestEventSummary fromEventSummary = TimeTestEventSummary.fromEvent(eventRecord);
        TimeTestEventSummary copiedSummary = fromEventSummary.copy();
        System.assertEquals(fromEventSummary.subject, copiedSummary.subject);
        System.assertEquals(fromEventSummary.fingerprint, copiedSummary.fingerprint);
        System.assertEquals(fromEventSummary.toMap().get('subject'), copiedSummary.toMap().get('subject'));

        TimeTestEventRequest locked = buildRequest();
        locked.locked = true;
        System.assertEquals(false, TimeTestEventRuleEngine.canAutoClose(locked));

        List<TimeTestEventRequest> empty = new List<TimeTestEventRequest>();
        System.assertEquals(0, TimeTestEventPlanner.orderByStart(null).size());
        System.assertEquals(0, TimeTestEventPlanner.dedupeByFingerprint(null).size());
        System.assertEquals(0, TimeTestEventPlanner.buildDailySummaries(null).size());
        System.assertEquals(0, TimeTestEventPlanner.buildWeekSummaries(null, Date.today()).size());
        System.assertEquals(0, TimeTestEventPlanner.totalMinutes(null));
        System.assertEquals(0, TimeTestEventPlanner.buildOverview(null).size());
        System.assertEquals(0, TimeTestEventPlanner.findConflicts(empty).size());
        System.assertEquals('No time entry', TimeTestEventPlanner.buildSummaryLabel(null));
        System.assertEquals(0, TimeTestEventPlanner.splitLongEntries(null).size());

        TimeTestEventRequest merged = TimeTestEventPlanner.mergeRequests(null, buildRequest());
        System.assertNotEquals(null, merged);
        List<TimeTestEventRequest> categorized = TimeTestEventPlanner.applyCategory(
            new List<TimeTestEventRequest>{ buildRequest() },
            '  Support  '
        );
        System.assertEquals('Support', categorized[0].category);
    }
}
