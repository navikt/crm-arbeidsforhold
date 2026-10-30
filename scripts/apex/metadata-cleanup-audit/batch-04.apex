List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('CustomApplication', 'Arbeidsforhold_henvendelse'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Agreement__c.EventAccess__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application__c.ApplicationDeadline__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application__c.EventAccess__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application_Decision__c.isDetailStatusFilled__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application_Decision__c.isNotNull__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application_Decision_Details__c.Letter_complaint_section__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application_Decision_Details__c.Letter_terms_section__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'Application_Decision_Details__c.Processing_basis_status__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateBusiness__c')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_04\n' + JSON.serializePretty(results));
