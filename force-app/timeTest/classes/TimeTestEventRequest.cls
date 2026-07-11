public with sharing class TimeTestEventRequest {
    @AuraEnabled
    public Id eventId { get; set; }

    @AuraEnabled
    public Id ownerId { get; set; }

    @AuraEnabled
    public String subject { get; set; }

    @AuraEnabled
    public String description { get; set; }

    @AuraEnabled
    public String location { get; set; }

    @AuraEnabled
    public Datetime startDateTime { get; set; }

    @AuraEnabled
    public Datetime endDateTime { get; set; }

    @AuraEnabled
    public Boolean allDay { get; set; }

    @AuraEnabled
    public String showAs { get; set; }

    @AuraEnabled
    public String category { get; set; }

    @AuraEnabled
    public Boolean locked { get; set; }

    public TimeTestEventRequest() {
        this.allDay = false;
        this.locked = false;
    }

    public static TimeTestEventRequest fromEvent(Event eventRecord) {
        TimeTestEventRequest request = new TimeTestEventRequest();
        if (eventRecord == null) {
            return request;
        }

        request.eventId = eventRecord.Id;
        request.ownerId = eventRecord.OwnerId;
        request.subject = eventRecord.Subject;
        request.description = eventRecord.Description;
        request.location = eventRecord.Location;
        request.startDateTime = eventRecord.StartDateTime;
        request.endDateTime = eventRecord.EndDateTime;
        request.allDay = eventRecord.IsAllDayEvent;
        request.showAs = eventRecord.ShowAs;
        return request;
    }

    public TimeTestEventRequest copy() {
        TimeTestEventRequest copyRequest = new TimeTestEventRequest();
        copyRequest.eventId = eventId;
        copyRequest.ownerId = ownerId;
        copyRequest.subject = subject;
        copyRequest.description = description;
        copyRequest.location = location;
        copyRequest.startDateTime = startDateTime;
        copyRequest.endDateTime = endDateTime;
        copyRequest.allDay = allDay;
        copyRequest.showAs = showAs;
        copyRequest.category = category;
        copyRequest.locked = locked;
        return copyRequest;
    }

    public void trimStrings() {
        subject = String.isBlank(subject) ? subject : subject.trim();
        description = String.isBlank(description) ? description : description.trim();
        location = String.isBlank(location) ? location : location.trim();
        category = String.isBlank(category) ? category : category.trim();
        showAs = String.isBlank(showAs) ? showAs : showAs.trim();
    }

    public void ensureDefaults() {
        if (String.isBlank(subject)) {
            subject = 'Time entry';
        }
        if (String.isBlank(showAs)) {
            showAs = 'Busy';
        }
        if (String.isBlank(category)) {
            category = 'General';
        }
        if (allDay == null) {
            allDay = false;
        }
        if (locked == null) {
            locked = false;
        }
    }

    public Boolean hasWindow() {
        return startDateTime != null && endDateTime != null;
    }

    public Boolean isAllDayMode() {
        return allDay == true;
    }

    public Boolean hasMeaningfulText() {
        return !String.isBlank(subject) || !String.isBlank(description) || !String.isBlank(location);
    }

    public Boolean matchesOwner(Id candidateOwnerId) {
        if (ownerId == null || candidateOwnerId == null) {
            return false;
        }
        return ownerId == candidateOwnerId;
    }

    public Integer requestedMinutes() {
        if (!hasWindow()) {
            return 0;
        }
        if (endDateTime <= startDateTime) {
            return 0;
        }
        Long millis = endDateTime.getTime() - startDateTime.getTime();
        if (millis <= 0) {
            return 0;
        }
        return Integer.valueOf(millis / 60000);
    }

    public TimeTestEventRequest withWindow(Datetime startValue, Datetime endValue) {
        TimeTestEventRequest request = copy();
        request.startDateTime = startValue;
        request.endDateTime = endValue;
        return request;
    }

    public TimeTestEventRequest shiftDays(Integer days) {
        TimeTestEventRequest request = copy();
        if (days == null || days == 0) {
            return request;
        }
        if (request.startDateTime != null) {
            request.startDateTime = request.startDateTime.addDays(days);
        }
        if (request.endDateTime != null) {
            request.endDateTime = request.endDateTime.addDays(days);
        }
        return request;
    }

    public Event toEvent() {
        Event eventRecord = new Event();
        eventRecord.Id = eventId;
        eventRecord.OwnerId = ownerId;
        eventRecord.Subject = subject;
        eventRecord.Description = description;
        eventRecord.Location = location;
        eventRecord.StartDateTime = startDateTime;
        eventRecord.EndDateTime = endDateTime;
        eventRecord.IsAllDayEvent = isAllDayMode();
        eventRecord.ShowAs = showAs;
        return eventRecord;
    }

    public String fingerprint() {
        List<String> parts = new List<String>{
            String.valueOf(ownerId),
            String.valueOf(startDateTime),
            String.valueOf(endDateTime),
            String.valueOf(subject),
            String.valueOf(location),
            String.valueOf(allDay),
            String.valueOf(showAs)
        };
        return String.join(parts, '|');
    }

    public String toDebugLabel() {
        List<String> parts = new List<String>();
        parts.add(String.isBlank(subject) ? 'Time entry' : subject);
        if (startDateTime != null) {
            parts.add(String.valueOf(startDateTime));
        }
        if (endDateTime != null) {
            parts.add(String.valueOf(endDateTime));
        }
        return String.join(parts, ' - ');
    }
}
