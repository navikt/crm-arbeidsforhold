@IsTest
public class AAREG_MultiSelectFlowValuesTest {
    @IsTest
    static void testMultiSelectFlowValuesWithMultipleItems() {
        List<String> tempList = new List<String>();
        tempList.add('Access API with dataprocessor');
        tempList.add('Access Online');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertNotEquals(null, result, 'List should not be null');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithEmptyList() {
        List<String> tempList = new List<String>();

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertEquals(0, result.size(), 'Result list should be empty');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithSingleSemicolonSeparatedValue() {
        List<String> tempList = new List<String>();
        tempList.add('value1;value2;value3');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one list');
        System.assertEquals(3, result[0].size(), 'Should split into 3 values');
        System.assertEquals('value1', result[0][0], 'First value should match');
        System.assertEquals('value2', result[0][1], 'Second value should match');
        System.assertEquals('value3', result[0][2], 'Third value should match');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithNullInput() {
        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(null);
        System.Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for null input');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithNorwegianCharacters() {
        List<String> tempList = new List<String>();
        tempList.add('Øst;Vest;Nord;Sør');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list');
        System.assertEquals(4, result[0].size(), 'Should have 4 values');
        System.assertEquals('Øst', result[0][0], 'Should handle Norwegian characters');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithEmptyString() {
        List<String> tempList = new List<String>();
        tempList.add('');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one list');
        System.assertEquals(1, result[0].size(), 'Should contain one empty element');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithSpecialCharacters() {
        List<String> tempList = new List<String>();
        tempList.add('item@1;item#2;item$3');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertEquals(3, result[0].size(), 'Should handle special characters');
        System.assertEquals('item@1', result[0][0], 'First special character preserved');
    }

    @IsTest
    static void testMultiSelectFlowValuesWithSpacesInValues() {
        List<String> tempList = new List<String>();
        tempList.add('value one;value two;value three');

        System.Test.startTest();
        List<List<String>> result = AAREG_MultiSelectFlowValues.checkSelectedValues(tempList);
        System.Test.stopTest();

        System.assertEquals(3, result[0].size(), 'Should split correctly');
        System.assertEquals('value one', result[0][0], 'Spaces should be preserved');
    }
}
