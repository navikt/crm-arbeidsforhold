public without sharing class AAREG_accountSelector{
    
   public static list<Account> selectAccountByOrganizationNumber(String organizationNumber){
       list<Account> accList = new list<Account>();
       if(organizationNumber!=null){
          accList = Database.query('SELECT id FROM Account WHERE INT_OrganizationNumber__c =:organizationNumber LIMIT 1');	
       }
       return accList; 
   }
}