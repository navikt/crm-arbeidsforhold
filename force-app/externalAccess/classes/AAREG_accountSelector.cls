/**
 * This class is responsible for selecting accounts from the AAREG system.
 * It operates without sharing rules, meaning it does not enforce the
 * organization's sharing model. Ensure proper security measures are in place
 * when using this class to handle sensitive data.
 */
public without sharing class AAREG_accountSelector{
    
   /**
    * Selects a list of Account records based on the provided organization number.
    *
    * @param organizationNumber The organization number used to filter Account records.
    * @return A list of Account records that match the given organization number.
    */
   public static list<Account> selectAccountByOrganizationNumber(String organizationNumber){
       list<Account> accList = new list<Account>();
       if(organizationNumber!=null){
          accList = Database.query('SELECT id FROM Account WHERE INT_OrganizationNumber__c =:organizationNumber LIMIT 1');	
       }
       return accList; 
   }

   /**
    * Selects a list of Person Account records based on the provided user ID.
    *
    * @param userId The user ID used to filter Person Account records.
    * @return A list of Person Account records that match the given user ID. Only the first matching record is returned.
    */
   public static list<Account> selectPersonAccountByUserId(String userId){
       list<Account> accList = new list<Account>();
       if(userId!=null){
          accList = Database.query('SELECT id FROM Account WHERE AccountOwnerId =:userId AND IsPersonAccount = true LIMIT 1');	
       }
       return accList; 
   }
}