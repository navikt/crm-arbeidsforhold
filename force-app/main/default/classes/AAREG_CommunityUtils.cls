public without sharing class AAREG_CommunityUtils {
  @AuraEnabled
  public static String getUserRights(String userId, String organiationNumber) {
    AltinnCalloutService altinn = new AltinnCalloutService();
    return JSON.serialize(altinn.getRights(userId, organiationNumber));
  }
}
