global class AAREG_MultiSelectFlowValues {
  @InvocableMethod
  public static List<List<String>> checkSelectedValues(List<String> values) {
    if (values.isEmpty()) {
      return null;
    }
    List<String> newList = values[0].split(';');
    List<List<String>> finalList = new List<List<String>>();
    finalList.add(newList);
    return finalList;
  }
}