/**
 * @description Queueable som kjører PDF-generering asynkront fra trigger.
 * @group AAREG
 */
public with sharing class AAREG_ApplicationPdfQueueable implements Queueable {

    private Set<Id> applicationIds;

    public AAREG_ApplicationPdfQueueable(Set<Id> applicationIds) {
        this.applicationIds = applicationIds;
    }

    public void execute(QueueableContext context) {
        AAREG_ApplicationPdfService.generatePdfs(applicationIds);
    }
}