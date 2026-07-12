public with sharing class TimeTestEventSummary {
    @AuraEnabled
    public Id eventId { get; set; }

    @AuraEnabled
    public Id ownerId { get; set; }

    @AuraEnabled
    public String subject { get; set; }

    @AuraEnabled
    public Datetime startDateTime { get; set; }

    @AuraEnabled
    public Datetime endDateTime { get; set; }

    @AuraEnabled
    public Integer durationMinutes { get; set; }

    @AuraEnabled
    public Decimal durationHours { get; set; }

    @AuraEnabled
    public String dayLabel { get; set; }

    @AuraEnabled
    public String statusLabel { get; set; }

    @AuraEnabled
    public Boolean allDay { get; set; }

    @AuraEnabled
    public Boolean valid { get; set; }

    @AuraEnabled
    public String validationMessage { get; set; }

    @AuraEnabled
    public String fingerprint { get; set; }

    public TimeTestEventSummary() {
        this.valid = true;
    }

    public static TimeTestEventSummary fromRequest(TimeTestEventRequest request) {
        TimeTestEventSummary summary = new TimeTestEventSummary();
        if (request == null) {
            summary.valid = false;
            summary.validationMessage = 'Request was null.';
            return summary;
        }

        summary.eventId = request.eventId;
        summary.ownerId = request.ownerId;
        summary.subject = request.subject;
        summary.startDateTime = request.startDateTime;
        summary.endDateTime = request.endDateTime;
        summary.durationMinutes = request.requestedMinutes();
        summary.durationHours = TimeTestEventRuleEngine.calculateHours(summary.durationMinutes);
        summary.dayLabel = request.startDateTime == null ? null : String.valueOf(request.startDateTime.date());
        summary.statusLabel = request.isAllDayMode() ? 'All day' : request.showAs;
        summary.allDay = request.allDay;
        summary.fingerprint = request.fingerprint();
        return summary;
    }

    public static TimeTestEventSummary fromEvent(Event eventRecord) {
        return fromRequest(TimeTestEventRequest.fromEvent(eventRecord));
    }

    public TimeTestEventSummary copy() {
        TimeTestEventSummary copySummary = new TimeTestEventSummary();
        copySummary.eventId = eventId;
        copySummary.ownerId = ownerId;
        copySummary.subject = subject;
        copySummary.startDateTime = startDateTime;
        copySummary.endDateTime = endDateTime;
        copySummary.durationMinutes = durationMinutes;
        copySummary.durationHours = durationHours;
        copySummary.dayLabel = dayLabel;
        copySummary.statusLabel = statusLabel;
        copySummary.allDay = allDay;
        copySummary.valid = valid;
        copySummary.validationMessage = validationMessage;
        copySummary.fingerprint = fingerprint;
        return copySummary;
    }

    public void markInvalid(String message) {
        valid = false;
        validationMessage = message;
    }

    public void markValid() {
        valid = true;
        validationMessage = null;
    }

    public Boolean hasDuration() {
        return durationMinutes != null && durationMinutes > 0;
    }

    public String hoursText() {
        if (durationHours == null) {
            return '0.00';
        }
        return String.valueOf(durationHours.setScale(2));
    }

    public String titleOrFallback() {
        return String.isBlank(subject) ? 'Time entry' : subject;
    }

    public String dayKey() {
        return String.isBlank(dayLabel) ? 'unknown' : dayLabel;
    }

    public String statusText() {
        return String.isBlank(statusLabel) ? 'Unspecified' : statusLabel;
    }

    public Map<String, Object> toMap() {
        Map<String, Object> result = new Map<String, Object>();
        result.put('eventId', eventId);
        result.put('ownerId', ownerId);
        result.put('subject', subject);
        result.put('startDateTime', startDateTime);
        result.put('endDateTime', endDateTime);
        result.put('durationMinutes', durationMinutes);
        result.put('durationHours', durationHours);
        result.put('dayLabel', dayLabel);
        result.put('statusLabel', statusLabel);
        result.put('allDay', allDay);
        result.put('valid', valid);
        result.put('validationMessage', validationMessage);
        result.put('fingerprint', fingerprint);
        return result;
    }
}
