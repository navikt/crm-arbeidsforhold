List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'P360_ExceptionTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'P360_RpcDtoTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventController'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventControllerTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventPlanner'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventRequest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventRuleEngine'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'TimeTestEventSummary'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexTestSuite', 'ArchiveTests'),
    new AAREG_MetadataCleanupAudit.Candidate('CustomApplication', 'Arbeidsforhold')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_03\n' + JSON.serializePretty(results));
