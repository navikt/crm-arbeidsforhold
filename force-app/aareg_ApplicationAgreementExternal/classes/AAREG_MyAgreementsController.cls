/**
 * @description Controller for the "My Agreements" LWC. Returns the agreements
 * belonging to the organization the user last selected.
 */
public with sharing class AAREG_MyAgreementsController {
  /**
   * @description Returns active agreements for the organization last used by the given user.
   * @param userId Id of the user whose last used organization should be looked up.
   * @return List of AAREG_Agreement wrappers; empty list when no organization is set.
   */
  @AuraEnabled(cacheable=true)
  public static List<AAREG_Agreement> getUsersAgreements(String userId) {
    String lastUsedOrganization = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId WITH USER_MODE]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      return getAgreements(lastUsedOrganization);
    } else {
      return new List<AAREG_Agreement>();
    }
  }

  /**
   * @description Queries active agreements for the given organization number and maps
   * them to AAREG_Agreement wrappers.
   * @param lastUsedOrganization Organization number to filter agreements by.
   * @return List of AAREG_Agreement wrappers for active agreements.
   */
  private static List<AAREG_Agreement> getAgreements(String lastUsedOrganization) {
    List<AAREG_Agreement> agreementWrapperTempList = new List<AAREG_Agreement>();

    List<Agreement__c> agreements = [
      SELECT Id,CreatedDate, Name, Status__c, Application__c
      FROM Agreement__c
      WHERE OrganizationNumber__c = :lastUsedOrganization
      WITH USER_MODE
    ];

    if (agreements != null) {
      for (Agreement__c agg : agreements) {
        AAREG_Agreement tempList = new AAREG_Agreement();
        tempList.avtaleId = agg.Id;
        tempList.avtaleDato = agg.CreatedDate;
        tempList.avtaleNummer = agg.Name;
        tempList.soknadsNummer = agg.Application__c;
        tempList.status = translateStatus(agg.Status__c);
        agreementWrapperTempList.add(tempList);
      }
    }

    return agreementWrapperTempList;
  }

  /**
   * @description Translates an agreement status code into a Norwegian display label.
   * @param status Status value from the Agreement__c record.
   * @return Localized status label, or 'Ukjent status' when the value is not recognized.
   */
  private static String translateStatus(String status) {
    Map<String, String> statusLabels = new Map<String, String>{
      'Active' => 'Aktiv',
      'Deactivated' => 'Avsluttet'
    };
    return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
  }
}