public without sharing class AAREG_CommunityUtils {
  @AuraEnabled
  public static AltinnCalloutService.AltinnRightsResponse getUserRights(String userId, String organiationNumber) {
    AltinnCalloutService altinn = new AltinnCalloutService();
    AltinnCalloutService.AltinnRightsResponse response = altinn.getRights(userId, organiationNumber);
    return response;
  }
}
