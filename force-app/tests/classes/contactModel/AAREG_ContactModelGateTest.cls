/**
 * Tests the fail-closed contact model switches.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelGateTest {
    @IsTest
    static void missingFlagIsOff() {
        AAREG_ContactModelTestDataFactory.setFlags(new Map<String, Boolean>(), null);

        System.Assert.isFalse(
            AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.SHADOW_WRITE),
            'A missing flag record must mean off'
        );
    }

    @IsTest
    static void disabledFlagIsOff() {
        AAREG_ContactModelTestDataFactory.setShadowWrite(false);

        System.Assert.isFalse(
            AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.SHADOW_WRITE),
            'A disabled flag must be off'
        );
    }

    @IsTest
    static void enabledGlobalFlagIsOnForMinimumAccessUser() {
        User minimumAccessUser = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Global', null);
        AAREG_ContactModelTestDataFactory.setShadowWrite(true);

        System.runAs(minimumAccessUser) {
            System.Assert.isTrue(
                AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.SHADOW_WRITE),
                'An enabled flag without permission requirement is on for everyone'
            );
        }
    }

    @IsTest
    static void pilotFlagIsOffForUserOutsidePilot() {
        User minimumAccessUser = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Outside', null);
        setPilotFlag();

        System.runAs(minimumAccessUser) {
            System.Assert.isFalse(
                AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.ORG_SELECTOR),
                'A pilot flag must be off for users without the pilot permission'
            );
        }
    }

    @IsTest
    static void pilotFlagIsOnForPilotUser() {
        User pilotUser = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Pilot', 'AAREG_ContactModel_Pilot');
        setPilotFlag();

        System.runAs(pilotUser) {
            System.Assert.isTrue(
                AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.ORG_SELECTOR),
                'A pilot flag must be on for users with the pilot permission'
            );
        }
    }

    @IsTest
    static void describeAllListsEveryFlagInRolloutOrder() {
        AAREG_ContactModelTestDataFactory.setShadowWrite(true);

        List<AAREG_ContactModelGate.FlagStatus> statuses = AAREG_ContactModelGate.describeAll();

        System.Assert.areEqual(5, statuses.size(), 'All five flags are described');
        System.Assert.areEqual(AAREG_ContactModelGate.SHADOW_WRITE, statuses[0].name, 'Shadow write comes first');
        System.Assert.isTrue(statuses[0].activeForCurrentUser, 'Shadow write is active');
        System.Assert.isFalse(statuses[1].exists, 'Flags without records are reported as missing');
    }

    private static void setPilotFlag() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{ AAREG_ContactModelGate.ORG_SELECTOR => true },
            new Map<String, String>{ AAREG_ContactModelGate.ORG_SELECTOR => 'AAREG_ContactModelPilot' }
        );
    }
}
