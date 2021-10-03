@isTest
public class AAREG_MultiSelectFlowValuesTest {
@isTest
    static void MultiSelectFlowValuesTestNotEmpty(){
        List<string> tempLst = new list<string>();
        tempLst.add('Access API with dataprocessor');
        tempLst.add('Access Online');
        AAREG_MultiSelectFlowValues.CheckSelectedValues(tempLst);
        System.assert(!tempLst.isEmpty(),'List should be not empty');
        
    }
    
    @isTest
    static void MultiSelectFlowValuesTestIsEmpty(){
        List<string> tempLst = new list<string>();
        AAREG_MultiSelectFlowValues.CheckSelectedValues(tempLst);
        System.assert(tempLst.isEmpty(),'List should be empty');
    }
}