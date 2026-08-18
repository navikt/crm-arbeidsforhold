/**
 * Test class for AAREG_AccessRequestTasksController.
 *
 * @author Ann Kristin Olsen
 * @since August 2026
 * @group AAREG Internal Application
 */
@IsTest
public class AAREG_AccessRequestTasksControllerTest {
    /**
     * getTasks should return only the tasks linked to the given access request.
     *
     * @since August 2026
     */
    @IsTest
    static void returnsTasksForAccessRequest() {
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;

        Task matchingTask = new Task(
            Subject = 'Access request task',
            Description = 'Task linked to access request',
            Status = 'Not Started',
            Priority = 'Normal',
            AAREG_AccessRequest__c = accessRequest.Id
        );
        insert matchingTask;

        Task otherTask = new Task(
            Subject = 'Other task',
            Description = 'Should not be returned',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert otherTask;

        Test.startTest();
        List<Task> result = AAREG_AccessRequestTasksController.getTasks(accessRequest.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(matchingTask.Id, result[0].Id);
        System.assertEquals('Access request task', result[0].Subject);
        System.assertEquals('Task linked to access request', result[0].Description);
        System.assertEquals(accessRequest.Id, result[0].AAREG_AccessRequest__c);
    }

    /**
     * getTasks should return an empty list when the record Id is null.
     *
     * @since August 2026
     */
    @IsTest
    static void returnsEmptyListWhenRecordIdIsNull() {
        Test.startTest();
        List<Task> result = AAREG_AccessRequestTasksController.getTasks(null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }
}
