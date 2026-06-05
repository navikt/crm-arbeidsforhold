@IsTest
public class AAREG_MultiSelectFlowValuesTest {
  @IsTest
  static void multiSelectFlowValuesTestNotEmpty(){
    List<String> tempList = new List<String>();
    tempList.add('Access API with dataprocessor');
    tempList.add('Access Online');

    System.Test.startTest();
    List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
    System.Test.stopTest();

    System.assertNotEquals(null, result, 'List should be not empty.');
  }
    
  @IsTest
  static void multiSelectFlowValuesTestIsEmpty(){
    List<String> tempList = new List<String>();

    System.Test.startTest();
    List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
    System.Test.stopTest();

    System.assertEquals(0, result.size(), 'Result list should be empty.');
  }
}