@isTest
public class AAREG_WebsakXMLGeneratorTest {
  @isTest
  private static void testXMLGeneration() {
    Map<String, String> documents = new Map<String, String>{
      'Test Document 1.docx' => '.docx',
      'Test Document 2.xlsx' => '.xlsx'
    };
    Date currDate = date.newInstance(2021, 7, 13);
    AAREG_WebsakXMLGenerator generator = new AAREG_WebsakXMLGenerator()
      .businessUnitId('1234Id')
      .businessUnitName('Test BU name')
      .journalPostStatus('J')
      .journalPostType('I')
      .journalPostName('S000047_SOKNAD_202110903')
      .applicationId('1234AppID')
      .userNavIdent('1234UserNavIdent')
      .organizationName('Test Organization')
      .organizationNumber('123456789')
      .mailingAddress('Test 123')
      .mailingCity('Oslo')
      .mailingPostalCode('0234')
      .submissionDate(currDate)
      .documentNameFormat(documents)
      .build();

    String xmlString = generator.generateXML();
    StaticResource resource = [SELECT Id, Body FROM StaticResource WHERE Name = 'WebsakXMLManifest' LIMIT 1];
    String expectedXml = resource.Body.toString().remove('\n');

    System.assertEquals(expectedXml, xmlString, 'XML generated correctly');
  }
}
