@isTest
public class AAREG_WebsakXMLGeneratorTest {
  @isTest
  private static void testXMLGeneration() {
    Map<String, String> documents = new Map<String, String>{
      'Test Document 1' => '.docx',
      'Test Document 2' => '.xlsx'
    };
    AAREG_WebsakXMLGenerator generator = new AAREG_WebsakXMLGenerator()
      .businessUnitId('1234Id')
      .businessUnitName('Test BU name')
      .journalPostStatus('J')
      .journalPostType('I')
      .applicationId('1234AppID')
      .userNavIdent('1234UserNavIdent')
      .documentNameFormat(documents)
      .build();

    String xmlString = generator.generateXml();
    StaticResource resource = [SELECT Id, Body FROM StaticResource WHERE Name = 'WebsakXMLManifest' LIMIT 1];
    String expectedXml = resource.Body.toString().remove('\n');

    System.assertEquals(expectedXml, xmlString, 'XML generated correctly');
  }
}
