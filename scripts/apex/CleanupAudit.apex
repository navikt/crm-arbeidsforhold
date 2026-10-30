List<AAREG_MetadataCleanupAudit.Candidate> candidates =
    new List<AAREG_MetadataCleanupAudit.Candidate>{
        new AAREG_MetadataCleanupAudit.Candidate(
            'ApexClass', 'AAREG_CheckObjectTypeNamingTest'
        ),
        new AAREG_MetadataCleanupAudit.Candidate(
            'Flow', 'AAREG_createDistributionAccess'
        )
    };

System.debug(LoggingLevel.INFO, JSON.serializePretty(
    AAREG_MetadataCleanupAudit.checkCandidates(candidates)
));