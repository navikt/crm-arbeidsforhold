List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_ArchiveServiceTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_CheckObjectTypeNamingTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_DecisionArchiveBatch'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_DecisionArchiveBatchTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_MyAppsCoverageTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_WebsakXMLGenerator'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'AAREG_WebsakXMLGeneratorTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'CRM_ApplicationDomain'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'P360_ArchiveDtoTest'),
    new AAREG_MetadataCleanupAudit.Candidate('ApexClass', 'P360_ContractDtoTest')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_02\n' + JSON.serializePretty(results));
