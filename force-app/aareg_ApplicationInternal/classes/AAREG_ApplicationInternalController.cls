public with sharing class AAREG_ApplicationInternalController {

  /*
   * wrapperclass
   **/
  public class ApplicationWrapper {
    @AuraEnabled public List<AAREG_ApplicationInternal> application{get; set;}
    @AuraEnabled public List<AAREG_BasisCodesInternal> basisCodes{get; set;}
    @AuraEnabled public List<AAREG_RelatedContactInternal> relatedContacts{get; set;}

    /*
    * Constructor
    **/
    public ApplicationWrapper(List<AAREG_ApplicationInternal> application,
                              List<AAREG_BasisCodesInternal> basisCodes,
                              List<AAREG_RelatedContactInternal> relatedContacts) {
        this.application = application;
        this.basisCodes = basisCodes;
        this.relatedContacts = relatedContacts;

  }
}

private static String translateOrganizationType (String orgType) {
  if (orgType == 'County') {
    return 'Fylke';
  } else if (orgType == 'State') {
    return 'Stat';
  } else if (orgType == 'Municipality') {
    return 'Kommune';
  } else if (orgType == 'Pension') {
    return 'Pensjon';
  } else if (orgType == 'Electricity Supervision') {
    return 'Eltilsyn';
  } else if (orgType == 'Other') {
    return 'Annet';
  } else {
    return orgType;
  }
}

@AuraEnabled
public static ApplicationWrapper getApplicationDetails(Id recordId) {
  List<AAREG_ApplicationInternal> applicationWrapperTempList = new List<AAREG_ApplicationInternal>();
  List<AAREG_BasisCodesInternal> basisCodesWrapperTempList = new List<AAREG_BasisCodesInternal>();
  List<AAREG_RelatedContactInternal> relatedContactsWrapperTempList = new List<AAREG_RelatedContactInternal>();
    
  List<Application__c> application = [
        SELECT Id,
               Name,
               APIAccess__c,
               ExtractionAccess__c,
               OnlineAccess__c,
               AccountId__c, 
               AccountName__c, 
               Account__c, 
               ApplicationDeadlineForReply__c, 
               ApplicationSubmittedDate__c,
               Casehandler_Status__c, 
               Contact__c, 
               DataProcessorName__c, 
               DataProcessorOrganizationNumber__c, 
               Email__c, 
               MailingAddress__c, 
               MailingCity__c, 
               MailingPostalCode__c,
               OrganizationNumber__c,
               OrganizationStructure__c, 
               TermsOfUse__c
        FROM Application__c
        WHERE Id = :recordId
        LIMIT 1
    ];

    if (application != null) {
        for(Application__c app : application){
          AAREG_ApplicationInternal tempList = new AAREG_ApplicationInternal();
          tempList.SoknadsId = app.Id;
          tempList.SoknadsNavn = app.Name;
          tempList.APITilgang = app.APIAccess__c;
          tempList.Uttrekk = app.ExtractionAccess__c;
          tempList.WebTilgang = app.OnlineAccess__c;
          tempList.KonsumentId = app.Account__c;
          tempList.KonsumentNavn = app.AccountName__c;
          tempList.KonsumentKontaktNavn = app.Contact__c;
          tempList.KonsumentOrganisasjonsnummer = app.OrganizationNumber__c;
          tempList.KonsumentAdresse = app.MailingAddress__c;
          tempList.KonsumentPoststed = app.MailingCity__c;
          tempList.KonsumentPostnummer = app.MailingPostalCode__c;
          tempList.KonsumentEpost = app.Email__c;
          tempList.OrganisasjonsType = translateOrganizationType(app.OrganizationStructure__c);
          tempList.SoknadLevert = app.ApplicationSubmittedDate__c;
          tempList.Svarfrist = app.ApplicationDeadlineForReply__c;
          tempList.Vilkaar = app.TermsOfUse__c;
          tempList.DatabehandlerNavn = app.DataProcessorName__c;
          tempList.DatabehandlerOrganisasjonsnummer = app.DataProcessorOrganizationNumber__c;
          applicationWrapperTempList.add(tempList);
        }
    }

    List<ApplicationBasisCode__c> basisCodes = [
      SELECT Id,
             Name,
             Application__c,
             ProcessingBasis__c,
             LegalBasisCounty__c,
             LegalBasisElectricitySupervision__c,
             LegalBasisMunicipality__c,
             LegalBasisPension__c,
             LegalBasisState__c,
             OrganizationType__c,
             OtherLegalBasis__c,
             OtherPurpose__c,
             PurposeCounty__c,
             PurposeElectricitySupervision__c,
             PurposeMunicipality__c,
             PurposePension__c,
             PurposeState__c,
             API_Access__c,
             Online_Access__c,
             Extraction_Access__c
             FROM ApplicationBasisCode__c
      WHERE Application__c = :recordId
  ];

  if(basisCodes != null && !basisCodes.isEmpty()) {
    
      for(ApplicationBasisCode__c code : basisCodes) {
        AAREG_BasisCodesInternal tempList = new AAREG_BasisCodesInternal();
        tempList.KodeverkId = code.Id;
        tempList.KodeverkNummer = code.Name;
        tempList.SoknadsId = code.Application__c;
        tempList.APITilgang = code.API_Access__c;
        tempList.Uttrekk = code.Extraction_Access__c;
        tempList.WebTilgang = code.Online_Access__c;
        tempList.Behandlingsgrunnlag = code.ProcessingBasis__c;
        if(code.OrganizationType__c == 'County'){
          tempList.Hjemmel = code.LegalBasisCounty__c;
          tempList.Formaal = code.PurposeCounty__c;
        }
        if(code.OrganizationType__c == 'State'){
          tempList.Hjemmel = code.LegalBasisState__c;
          tempList.Formaal = code.PurposeState__c;
        }
        if(code.OrganizationType__c == 'Municipality'){
          tempList.Hjemmel = code.LegalBasisMunicipality__c;
          tempList.Formaal = code.PurposeMunicipality__c;
        }
        if(code.OrganizationType__c == 'Pension'){
          tempList.Hjemmel = code.LegalBasisPension__c;
          tempList.Formaal = code.PurposePension__c;
        }
        if(code.OrganizationType__c == 'Electricity Supervision'){
          tempList.Hjemmel = code.LegalBasisElectricitySupervision__c;
          tempList.Formaal = code.PurposeElectricitySupervision__c;
        }
        if(code.OrganizationType__c == 'Other'){
          tempList.Hjemmel = code.OtherLegalBasis__c;
          tempList.Formaal = code.OtherPurpose__c;
        }
        tempList.OrganisasjonsType = translateOrganizationType(code.OrganizationType__c);
        tempList.AndreHjemmel = code.OtherLegalBasis__c;
        tempList.AndreFormaal = code.OtherPurpose__c;
        basisCodesWrapperTempList.add(tempList);
      }
  }

    List<RelatedContact__c> relatedContacts = [
      SELECT Id,
            Name,
            Phone__c,
            Email__c,
            AgreementNotifications__c,
            ChangeNotifications__c,
            ErrorMessageNotifications__c,
            SecurityNotifications__c
      FROM RelatedContact__c
      WHERE Application__c = :recordId
  ];

  if(relatedContacts != null && !relatedContacts.isEmpty()) {
    
      for(RelatedContact__c con : relatedContacts) {
        AAREG_RelatedContactInternal tempList = new AAREG_RelatedContactInternal();
        tempList.KontaktId = con.Id;
        tempList.KontaktNavn = con.Name;
        tempList.KontaktTelefon = con.Phone__c;
        tempList.KontaktEpost = con.Email__c;
        tempList.AvtaleVarsel = con.AgreementNotifications__c;
        tempList.EndringsVarsel = con.ChangeNotifications__c;
        tempList.FeilmeldingsVarsel = con.ErrorMessageNotifications__c;
        tempList.SikkerhetsVarsel = con.SecurityNotifications__c;
        tempList.SoknadsId = recordId;
        relatedContactsWrapperTempList.add(tempList);
      }
    }

  return new ApplicationWrapper(applicationWrapperTempList, basisCodesWrapperTempList, relatedContactsWrapperTempList);
  }

}

  