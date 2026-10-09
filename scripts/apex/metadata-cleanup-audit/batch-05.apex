List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateGeneral__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateHealthAndSocial__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateLegal__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateMilitary__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.LegalBasisStateResearch__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateBusiness__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateGeneral__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateHealthAndSocial__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateLegal__c'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateMilitary__c')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_05\n' + JSON.serializePretty(results));
