global class AAREG_MultiSelectFlowValues {
   @InvocableMethod
   public static List<list<string>> CheckSelectedValues(List<String> values) {
      if(!(values.isEmpty())){
          string tempStr = values[0];
          List<String> lstnew = tempStr.split(';');
          list<list<string>> finalLst = new list<list<string>>();
          finalLst.add(lstnew);
          System.debug(finalLst);
          return finalLst;   
      }
      else return null;
   }
}