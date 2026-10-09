List<AAREG_MetadataCleanupAudit.Candidate> candidates = new List<AAREG_MetadataCleanupAudit.Candidate>{
    new AAREG_MetadataCleanupAudit.Candidate('PermissionSetGroup', 'AAREG_Arbeidsforhold_Saksbehandling_GroupSet'),
    new AAREG_MetadataCleanupAudit.Candidate('PermissionSetGroup', 'AAREG_Arbeidsforhold_Support_GroupSet'),
    new AAREG_MetadataCleanupAudit.Candidate('QuickAction', 'Application__c.aaReg_ApplicationDone'),
    new AAREG_MetadataCleanupAudit.Candidate('QuickAction', 'Application_Decision__c.AAREG_Create_agreement'),
    new AAREG_MetadataCleanupAudit.Candidate('RemoteSiteSetting', 'AAREG_DistribusjonTilgangAPI'),
    new AAREG_MetadataCleanupAudit.Candidate('Report', 'Aa_registerReports/Aa_regNewFourthAndOlder'),
    new AAREG_MetadataCleanupAudit.Candidate('Report', 'Aa_registerReports/aareg_oversikt_konsument_og_kontaktpersoner'),
    new AAREG_MetadataCleanupAudit.Candidate('ReportFolder', 'Aa_registerReports/AAREG_arbeidsforholdTeam'),
    new AAREG_MetadataCleanupAudit.Candidate('ReportType', 'Accounts_with_Applications_Decisions_Decision_Details'),
    new AAREG_MetadataCleanupAudit.Candidate('ReportType', 'Decision_Detail_Master_Application_Account')
};
List<AAREG_MetadataCleanupAudit.CheckResult> results = AAREG_MetadataCleanupAudit.checkCandidates(candidates);
System.debug(LoggingLevel.INFO, 'METADATA_AUDIT_BATCH_09\n' + JSON.serializePretty(results));
