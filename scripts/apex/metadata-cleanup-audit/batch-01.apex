List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ApplicationArchiveBatch'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ApplicationArchiveBatchTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ApplicationControllerCoverageTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveApplicationCommandTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveApplicationResultTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveBatchHandler'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveBatchHandlerTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveScheduler'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveSchedulerTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveService')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_01\n' + JSON.serializePretty(results));
