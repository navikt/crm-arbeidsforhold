/**
 * A global class used for handling multi-select flow values in the AAREG context.
 * This class is designed to be used within Salesforce flows to manage and process
 * multi-select values effectively.
 *
 * Note: The use of the global modifier should be carefully considered as it exposes
 * the class to external packages and namespaces.
 *
 * @author [Your Name]
 * @date [Date]
 * @group Utility
 * @group-content This class provides utility methods for handling multi-select values.
 */
global class AAREG_MultiSelectFlowValues {
  @InvocableMethod
  /**
   * Checks and processes the selected values from the provided list.
   *
   * @param values A list of strings representing the selected values.
   * @return A list of lists of strings after processing the selected values.
   */
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