global class AAREG_MultiSelectFlowValues {
  @InvocableMethod
  public static List<List<String>> checkSelectedValues(List<String> values) {
    if (values == null || values.isEmpty()) {
      return new List<List<String>>();
    }
    List<String> newList = values[0].split(';');
    List<List<String>> finalList = new List<List<String>>();
    finalList.add(newList);
    return finalList;
  }
}