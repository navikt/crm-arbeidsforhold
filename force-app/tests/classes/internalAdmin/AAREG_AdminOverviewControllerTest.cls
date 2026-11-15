/**
 * Behaviour tests for the Arbeidsforhold Admin overview.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminOverviewControllerTest {
    @TestSetup
    static void createData() {
        Account account = AAREG_TestDataFactory.getAccount();
        insert account;
        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;
    }

    private static AAREG_AdminOverviewController.Tile findTile(
        List<AAREG_AdminOverviewController.Tile> tiles,
        String key
    ) {
        for (AAREG_AdminOverviewController.Tile tile : tiles) {
            if (tile.key == key) {
                return tile;
            }
        }
        System.Assert.fail('Missing tile ' + key);
        return null;
    }

    @IsTest
    static void overviewCountsApplicationsByStatus() {
        System.Test.startTest();
        List<AAREG_AdminOverviewController.Tile> tiles = AAREG_AdminOverviewController.getOverview();
        System.Test.stopTest();

        AAREG_AdminOverviewController.Tile tile = findTile(tiles, 'applicationsByStatus');
        System.Assert.isTrue(tile.available, 'Admin should be able to read applications');
        System.Assert.areEqual(1, tile.count, 'One application exists');
        System.Assert.areEqual('New', tile.breakdown[0].label, 'Breakdown should be grouped by status');
        System.Assert.areEqual(1, tile.breakdown[0].count, 'One application is New');
    }

    @IsTest
    static void recentlyChangedOpenApplicationIsNotStuck() {
        System.Test.startTest();
        List<AAREG_AdminOverviewController.Tile> tiles = AAREG_AdminOverviewController.getOverview();
        System.Test.stopTest();

        AAREG_AdminOverviewController.Tile tile = findTile(tiles, 'stuckApplications');
        System.Assert.areEqual(0, tile.count, 'An application changed today is not stuck');
        System.Assert.isTrue(tile.description.contains('14'), 'Description should state the threshold');
    }

    @IsTest
    static void tileRecordsReturnRowsForDrillDown() {
        System.Test.startTest();
        List<AAREG_AdminOverviewController.RecordRow> rows = AAREG_AdminOverviewController.getTileRecords(
            'applicationsByStatus'
        );
        System.Test.stopTest();

        System.Assert.areEqual(1, rows.size(), 'Drill-down should list the application');
        System.Assert.areEqual('New', rows[0].detail, 'Detail should show the status');
        System.Assert.isNotNull(rows[0].id, 'Row should carry the record id for navigation');
    }

    @IsTest
    static void unknownTileKeyIsRejected() {
        try {
            AAREG_AdminOverviewController.getTileRecords('notATile');
            System.Assert.fail('Unknown keys must be rejected');
        } catch (AuraHandledException error) {
            System.Assert.isTrue(error.getMessage().contains('notATile'), 'Message should name the key');
        }
    }

    @IsTest
    static void minimumAccessUserSeesExplanationInsteadOfError() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        List<AAREG_AdminOverviewController.Tile> tiles;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            tiles = AAREG_AdminOverviewController.getOverview();
            System.Test.stopTest();
        }

        AAREG_AdminOverviewController.Tile tile = findTile(tiles, 'applicationsByStatus');
        System.Assert.isFalse(tile.available, 'Minimum access user cannot read applications');
        System.Assert.isNotNull(tile.message, 'Unavailable tile should explain why');
        System.Assert.isNull(tile.count, 'Unavailable tile should not report a count');
    }

    @IsTest
    static void viewerPermissionSetGrantsReadWithoutViewAll() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet viewer = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_Admin_Viewer' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = viewer.Id);
        List<AAREG_AdminOverviewController.Tile> tiles;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            tiles = AAREG_AdminOverviewController.getOverview();
            System.Test.stopTest();
        }

        AAREG_AdminOverviewController.Tile tile = findTile(tiles, 'applicationsByStatus');
        System.Assert.isTrue(tile.available, 'Viewer can read applications');
        System.Assert.areEqual(0, tile.count, 'Private records owned by others stay hidden without View All');
    }
}
