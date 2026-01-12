@isTest
public class AAREG_MultiSelectFlowValuesTest {
  @isTest
  static void multiSelectFlowValuesTestNotEmpty(){
    List<String> tempList = new List<String>();
    tempList.add('Access API with dataprocessor');
    tempList.add('Access Online');

    Test.startTest();
    List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
    Test.stopTest();

    System.assertNotEquals(null, result, 'List should be not empty.');
  }
    
  @isTest
  static void multiSelectFlowValuesTestIsEmpty(){
    List<String> tempList = new List<String>();

    Test.startTest();
    List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
    Test.stopTest();

    System.assertEquals(0, result.size(), 'Result list should be empty.');
  }
}