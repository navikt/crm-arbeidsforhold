/**
 * Read-only operational overview for the Arbeidsforhold Admin app.
 *
 * Each tile is a fixed, whitelisted query that runs in user mode, so object access, field access,
 * and sharing all follow the signed-in user. A tile the user cannot read is returned with an
 * explanation instead of failing the whole overview.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminOverviewController {
    @TestVisible
    private static final Integer DEFAULT_STUCK_AFTER_DAYS = 14;
    private static final Integer MAX_ROWS = 50;
    private static final List<String> OPEN_APPLICATION_STATUSES = new List<String>{
        'New',
        'In Progress',
        'Additional Information Required',
        'In Process'
    };
    private static final List<String> ERROR_LOG_LEVELS = new List<String>{ 'Error', 'Critical' };

    /**
     * One counted tile on the overview page.
     */
    public class Tile {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String objectApiName;
        @AuraEnabled
        public Boolean available = true;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Integer count;
        @AuraEnabled
        public List<BreakdownItem> breakdown = new List<BreakdownItem>();
    }

    /**
     * One group within a tile, for example one application status.
     */
    public class BreakdownItem {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Integer count;

        BreakdownItem(String label, Integer count) {
            this.label = label;
            this.count = count;
        }
    }

    /**
     * One record in a tile drill-down.
     */
    public class RecordRow {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String detail;
        @AuraEnabled
        public Datetime lastModified;
    }

    private class TileDefinition {
        String key;
        String label;
        String description;
        String objectApiName;
        String whereClause;
        String groupField;
        String detailField;
        Map<String, Object> binds;

        TileDefinition(String key, String label, String description, String objectApiName) {
            this.key = key;
            this.label = label;
            this.description = description;
            this.objectApiName = objectApiName;
            this.binds = new Map<String, Object>();
        }

        TileDefinition filteredBy(String whereClause, Map<String, Object> binds) {
            this.whereClause = whereClause;
            this.binds = binds;
            return this;
        }

        TileDefinition groupedBy(String groupField) {
            this.groupField = groupField;
            return this;
        }

        TileDefinition showing(String detailField) {
            this.detailField = detailField;
            return this;
        }

        String whereSuffix() {
            return String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause;
        }
    }

    /**
     * Returns all overview tiles with counts the current user is allowed to see.
     *
     * @return List<Tile> Tiles in display order.
     */
    @AuraEnabled(cacheable=false)
    public static List<Tile> getOverview() {
        List<Tile> tiles = new List<Tile>();
        for (TileDefinition definition : definitions()) {
            tiles.add(buildTile(definition));
        }
        return tiles;
    }

    /**
     * Returns up to 50 of the most recently modified records behind one tile.
     *
     * @param key Tile key from {@link #getOverview()}.
     * @return List<RecordRow> Rows the current user can see.
     * @throws AuraHandledException When the key is unknown or the records cannot be read.
     */
    @AuraEnabled(cacheable=false)
    public static List<RecordRow> getTileRecords(String key) {
        TileDefinition definition = findDefinition(key);
        String query =
            'SELECT Id, Name, LastModifiedDate, ' +
            definition.detailField +
            ' FROM ' +
            definition.objectApiName +
            definition.whereSuffix() +
            ' ORDER BY LastModifiedDate DESC LIMIT ' +
            MAX_ROWS;
        List<RecordRow> rows = new List<RecordRow>();
        try {
            for (SObject record : Database.queryWithBinds(query, definition.binds, AccessLevel.USER_MODE)) {
                RecordRow row = new RecordRow();
                row.id = record.Id;
                row.name = String.valueOf(record.get('Name'));
                row.detail = String.valueOf(record.get(definition.detailField));
                row.lastModified = (Datetime) record.get('LastModifiedDate');
                rows.add(row);
            }
        } catch (Exception error) {
            throw handledException('Kan ikkje lese postane for ' + definition.label + ': ' + error.getMessage());
        }
        return rows;
    }

    private static Tile buildTile(TileDefinition definition) {
        Tile tile = new Tile();
        tile.key = definition.key;
        tile.label = definition.label;
        tile.description = definition.description;
        tile.objectApiName = definition.objectApiName;
        if (!isReadable(definition.objectApiName)) {
            return markUnavailable(tile, 'Du har ikkje lesetilgang til ' + definition.objectApiName + '.');
        }
        try {
            tile.count = Database.countQueryWithBinds(
                'SELECT COUNT() FROM ' + definition.objectApiName + definition.whereSuffix(),
                definition.binds,
                AccessLevel.USER_MODE
            );
            if (definition.groupField != null) {
                tile.breakdown = breakdown(definition);
            }
        } catch (Exception error) {
            return markUnavailable(tile, 'Kunne ikkje telje postane: ' + error.getMessage());
        }
        return tile;
    }

    private static List<BreakdownItem> breakdown(TileDefinition definition) {
        String query =
            'SELECT ' +
            definition.groupField +
            ' groupValue, COUNT(Id) total FROM ' +
            definition.objectApiName +
            definition.whereSuffix() +
            ' GROUP BY ' +
            definition.groupField +
            ' ORDER BY COUNT(Id) DESC';
        List<BreakdownItem> items = new List<BreakdownItem>();
        for (SObject result : Database.queryWithBinds(query, definition.binds, AccessLevel.USER_MODE)) {
            Object groupValue = result.get('groupValue');
            items.add(
                new BreakdownItem(
                    groupValue == null ? '(tom)' : String.valueOf(groupValue),
                    (Integer) result.get('total')
                )
            );
        }
        return items;
    }

    private static Tile markUnavailable(Tile tile, String message) {
        tile.available = false;
        tile.message = message;
        tile.count = null;
        return tile;
    }

    private static Boolean isReadable(String objectApiName) {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
        return sObjectType != null && sObjectType.getDescribe().isAccessible();
    }

    private static TileDefinition findDefinition(String key) {
        for (TileDefinition definition : definitions()) {
            if (definition.key == key) {
                return definition;
            }
        }
        throw handledException('Ukjend flis: ' + key);
    }

    private static AuraHandledException handledException(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    @TestVisible
    private static Integer stuckAfterDays() {
        AAREG_Admin_Setting__mdt setting = AAREG_Admin_Setting__mdt.getInstance('Default');
        if (setting == null || setting.Stuck_After_Days__c == null || setting.Stuck_After_Days__c < 1) {
            return DEFAULT_STUCK_AFTER_DAYS;
        }
        return setting.Stuck_After_Days__c.intValue();
    }

    private static List<TileDefinition> definitions() {
        Integer stuckDays = stuckAfterDays();
        return new List<TileDefinition>{
            new TileDefinition(
                    'applicationsByStatus',
                    'Søknader per status',
                    'Alle søknader du kan sjå, fordelte på status.',
                    'Application__c'
                )
                .groupedBy('Status__c')
                .showing('Status__c'),
            new TileDefinition(
                    'stuckApplications',
                    'Søknader som står fast',
                    'Opne søknader som ikkje er endra på ' + stuckDays + ' dagar.',
                    'Application__c'
                )
                .filteredBy(
                    'Status__c IN :openStatuses AND LastModifiedDate < :cutoff',
                    new Map<String, Object>{
                        'openStatuses' => OPEN_APPLICATION_STATUSES,
                        'cutoff' => Datetime.now().addDays(-stuckDays)
                    }
                )
                .groupedBy('Status__c')
                .showing('Status__c'),
            new TileDefinition(
                    'decisionsAwaitingRelease',
                    'Vedtak som ventar på P360-frigjeving',
                    'Fullførte vedtak der «Klar for P360-arkivering» ikkje er sett.',
                    'Application_Decision__c'
                )
                .filteredBy(
                    'Process_status__c = :completed AND Ready_For_P360_Archive__c = false',
                    new Map<String, Object>{ 'completed' => 'Completed' }
                )
                .showing('Process_status__c'),
            new TileDefinition(
                    'p360JobsByStatus',
                    'P360-jobbar per status',
                    'Arkiveringsjobbar mot P360, fordelte på status.',
                    'P360_Archive_Job__c'
                )
                .groupedBy('Status__c')
                .showing('Status__c'),
            new TileDefinition(
                    'p360ExpiredLeases',
                    'P360-jobbar med utgått lease',
                    'Jobbar som står «In Progress», men der leasen har gått ut. Dei kan ha stoppa.',
                    'P360_Archive_Job__c'
                )
                .filteredBy(
                    'Status__c = :inProgress AND Lease_Expires_Date__c < :now',
                    new Map<String, Object>{ 'inProgress' => 'In Progress', 'now' => Datetime.now() }
                )
                .showing('Last_Error_Code__c'),
            new TileDefinition(
                    'errorLogs24h',
                    'Feil siste 24 timar',
                    'Feil- og kritiske loggar for Aa-registeret, fordelte på kjeldeklasse.',
                    'Application_Log__c'
                )
                .filteredBy(
                    'CreatedDate >= :since AND Log_Level__c IN :levels AND Application_Domain__c = :domain',
                    new Map<String, Object>{
                        'since' => Datetime.now().addHours(-24),
                        'levels' => ERROR_LOG_LEVELS,
                        'domain' => 'AAREG'
                    }
                )
                .groupedBy('Source_Class__c')
                .showing('Source_Class__c'),
            new TileDefinition(
                    'unassignedInquiries',
                    'Opne henvendingar utan eigar',
                    'Henvendingar med status New eller In progress som ingen har teke.',
                    'Inquiry__c'
                )
                .filteredBy(
                    'Status__c IN :openStatuses AND InquiryOwner__c = null',
                    new Map<String, Object>{ 'openStatuses' => new List<String>{ 'New', 'In progress' } }
                )
                .groupedBy('Status__c')
                .showing('Status__c')
        };
    }
}
