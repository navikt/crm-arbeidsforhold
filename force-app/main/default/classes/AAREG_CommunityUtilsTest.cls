@isTest
public class AAREG_CommunityUtilsTest {
  @TestSetup
  static void makeData() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = new User();

    user.FirstName = 'John';
    user.LastName = 'Doe';
    user.Email = 'John.Doe@nav.no';
    user.Username = 'John.Doe@nav.no';
    user.Alias = 'j.doe';
    user.LanguageLocaleKey = 'no';
    user.LocaleSidKey = 'no_NO';
    user.TimeZoneSidKey = 'Europe/Paris';
    user.EmailEncodingKey = 'UTF-8';
    user.ProfileId = profile.Id;
    user.Department = '1';
    user.LastUsedOrganization__c = '123456789';

    insert user;
  }

  @isTest
  static void testGetUserRights() {
    User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
    ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

    Test.startTest();
    AltinnCalloutService.AltinnRightsResponse response = AAREG_CommunityUtils.getUserRights(
      user.Id,
      '123456789',
      '5719'
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Expect success');
    System.assertEquals(null, response.errorMessage, 'Expect no error message');
    System.assertEquals(50, response.rights.size(), 'Expect 50 rights');
  }
}
