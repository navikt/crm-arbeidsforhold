public with sharing class AAREG_ApplicationDecisionController {
    @AuraEnabled
    public static List<AAREG_ApplicationDecision> getApplicationDecision(Id recordId) {
      List<AAREG_ApplicationDecision> decisionWrapperTempList = new List<AAREG_ApplicationDecision>();
     
      List<Application_Decision__c> decision = [
            SELECT Id, Name, CreatedDate, Application__c,Status__c, Process_status__c, Letter_complaint_text__c, Letter_terms_text__c 
            FROM Application_Decision__c
            WHERE Application__c = :recordId
        ];
    
        if (decision != null) {
            for(Application_Decision__c app : decision){
                AAREG_ApplicationDecision tempList = new AAREG_ApplicationDecision();
                templist.VedtaksNr = app.Name;
                tempList.VedtaksId = app.Id;
                tempList.SoknadsId = app.Application__c;
                tempList.Status = app.Status__c;
                tempList.StatusProsess = app.Process_status__c;
                decisionWrapperTempList.add(tempList);
            }
        }
    
       
      return decisionWrapperTempList;
      }

      @AuraEnabled
      public static ID createApplicationDecision(Id recordId) {
        Application_Decision__c newDecision = new Application_Decision__c();
        List<Application_Decision_Details__c> codeBaseList = new List<Application_Decision_Details__c>();
        ID NewDecisionId;

        newDecision.Application__c = recordId; // Replace with the correct field API name
        newDecision.Process_status__c = 'In progress'; // Set default values as needed
        newDecision.Letter_complaint_text__c = System.Label.AAREG_complaint_description_section;
        newDecision.Letter_terms_text__c = System.Label.AAREG_terms_description_section;
        newDecision.Letter_github_text__c = System.Label.AAREG_github_description_text;
        newDecision.Letter_webaccess_text__c = System.Label.AAREG_web_access_text;
        insert newDecision;
        NewDecisionId = newDecision.Id;

      List<ApplicationBasisCode__c> basisCodes = [
        SELECT Id,
              Name,
              API_Access__c,
              Extraction_Access__c,
              Online_Access__c,
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
              PurposeState__c
        FROM ApplicationBasisCode__c
        WHERE Application__c = :recordId
      ];

      for(ApplicationBasisCode__c app : basisCodes){
        Application_Decision_Details__c newDecisionDetails = new Application_Decision_Details__c(); 
        newDecisionDetails.Application_Decision__c = newDecision.Id;
        newDecisionDetails.API_Access__c =app.API_Access__c;
        newDecisionDetails.Extraction_Access__c =app.Extraction_Access__c;
        newDecisionDetails.Online_Access__c =app.Online_Access__c;
        newDecisionDetails.Processing_Basis__c =app.ProcessingBasis__c;
        if(app.OrganizationType__c == 'Other'){
            newDecisionDetails.Legal_Basis__c =app.OtherLegalBasis__c;
            newDecisionDetails.Purpose__c =app.OtherPurpose__c;
        }
        if(app.OrganizationType__c == 'State'){
            newDecisionDetails.Legal_Basis__c =app.LegalBasisState__c;
            newDecisionDetails.Purpose__c =app.PurposeState__c;
        }
        if(app.OrganizationType__c == 'Municipality'){
            newDecisionDetails.Legal_Basis__c =app.LegalBasisMunicipality__c;
            newDecisionDetails.Purpose__c =app.PurposeMunicipality__c;
        }
        if(app.OrganizationType__c == 'Pension'){
            newDecisionDetails.Legal_Basis__c =app.LegalBasisPension__c;
            newDecisionDetails.Purpose__c =app.PurposePension__c;
        }
        if(app.OrganizationType__c == 'Electricity Supervision'){
            newDecisionDetails.Legal_Basis__c =app.LegalBasisElectricitySupervision__c;
            newDecisionDetails.Purpose__c =app.PurposeElectricitySupervision__c;
        }
        if(app.OrganizationType__c == 'County'){
          newDecisionDetails.Legal_Basis__c =app.LegalBasisCounty__c;
          newDecisionDetails.Purpose__c =app.PurposeCounty__c;
        }
        if(app.OtherLegalBasis__c != null && app.OtherPurpose__c != null){ 
          newDecisionDetails.Legal_Basis__c =app.OtherLegalBasis__c;
          newDecisionDetails.Purpose__c =app.OtherPurpose__c;
        }
        codeBaseList.add(newDecisionDetails);
      }
      insert codeBaseList;
      return NewDecisionId;
    }
  }