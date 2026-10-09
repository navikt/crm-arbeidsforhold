List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('CustomField', 'ApplicationBasisCode__c.PurposeStateResearch__c'),
    new AAREG_MetadataCleanupAudit.Candidate('Dashboard', 'AaregistretDashboards/GKtYxPggRSehHAgZamtQodkAOOUTSD'),
    new AAREG_MetadataCleanupAudit.Candidate('Dashboard', 'AaregistretDashboards/GQvEviCLZeKewgTwnAaPTJEQJmzuEa'),
    new AAREG_MetadataCleanupAudit.Candidate('Dashboard', 'AaregistretDashboards/gRzFZpdxEiaCoJStEunYuFQsBNpjbe'),
    new AAREG_MetadataCleanupAudit.Candidate('Dashboard', 'CompanyDashboards/cJnGwvGCUSKVeTaRvFsWdJsGDkPlHk'),
    new AAREG_MetadataCleanupAudit.Candidate('Dashboard', 'CompanyDashboards/gRzFZpdxEiaCoJStEunYuFQsBNpjbe'),
    new AAREG_MetadataCleanupAudit.Candidate('EmailTemplate', 'unfiled$public/aaRegApplicationConfirmation_1622393053589'),
    new AAREG_MetadataCleanupAudit.Candidate('EmailTemplate', 'unfiled$public/aaRegApplicationConfirmation_1636046532436'),
    new AAREG_MetadataCleanupAudit.Candidate('FlexiPage', 'AAREG_CasehandlingRecordPage'),
    new AAREG_MetadataCleanupAudit.Candidate('FlexiPage', 'AgreementRecordPage')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_06\n' + JSON.serializePretty(results));
