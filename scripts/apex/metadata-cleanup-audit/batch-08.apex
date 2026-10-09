List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_updateDecisionText'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'Agreement_Initiator'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'Application_Processor'),
    new AAREG_MetadataCleanupAudit.Candidate('Layout', 'Application__c-Application Layout'),
    new AAREG_MetadataCleanupAudit.Candidate('Layout', 'Application_Decision_Details__c-Oppsettet Application Decision'),
    new AAREG_MetadataCleanupAudit.Candidate('LightningComponentBundle', 'aareg_ApplicationDecisionInternal'),
    new AAREG_MetadataCleanupAudit.Candidate('ListView', 'Inquiry__c.Aareg_SupportApplicationQuestions'),
    new AAREG_MetadataCleanupAudit.Candidate('ListView', 'Inquiry__c.Aareg_SupportProfessionalFunctionalQuestions'),
    new AAREG_MetadataCleanupAudit.Candidate('PathAssistant', 'ArbeidsforholdApplicationPath'),
    new AAREG_MetadataCleanupAudit.Candidate('PermissionSet', 'NAVArbeidsforhold')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_08\n' + JSON.serializePretty(results));
