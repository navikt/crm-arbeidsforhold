List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('FlexiPage', 'ApplicationRecordPage'),
    new AAREG_MetadataCleanupAudit.Candidate('FlexiPage', 'Home_Page_Default'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_applicationFinished'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_applicationFinished_RT'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_changeCasehandler'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_createDistributionAccess'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_Decision_create_agreement'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_getContactAndUpdateApplication'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_populateDecisionText'),
    new AAREG_MetadataCleanupAudit.Candidate('Flow', 'AAREG_subflowCreateTask_RT')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_07\n' + JSON.serializePretty(results));
