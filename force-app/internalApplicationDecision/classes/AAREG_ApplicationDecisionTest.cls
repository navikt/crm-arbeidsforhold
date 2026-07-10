/**
 * @description Test class for AAREG_ApplicationDecision wrapper class
 * Tests data encapsulation and property access for application decision LWC interface
 * @author AAREG Team
 * @version 66
 * @group Internal Application Decision
 */
@IsTest
public class AAREG_ApplicationDecisionTest {
    /**
     * @description Tests default constructor instantiation
     */
    @IsTest
    static void testDecisionInstantiation() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        Test.stopTest();

        System.Assert.isNotNull(decision, 'Decision should be instantiated');
    }

    /**
     * @description Tests setting and getting decision core properties
     */
    @IsTest
    static void testDecisionCoreProperties() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        decision.vedtaksId = '001000000000001';
        decision.vedtaksNr = 'VED-2026-001';
        decision.soknadsId = 'SØK-2026-001';
        decision.status = 'Godkjent';
        decision.statusProsess = 'Ferdig';
        Test.stopTest();

        System.assertEquals('001000000000001', decision.vedtaksId, 'Decision ID should be set');
        System.assertEquals('VED-2026-001', decision.vedtaksNr, 'Decision number should be set');
        System.assertEquals('SØK-2026-001', decision.soknadsId, 'Application ID should be set');
        System.assertEquals('Godkjent', decision.status, 'Status should be set');
        System.assertEquals('Ferdig', decision.statusProsess, 'Process status should be set');
    }

    /**
     * @description Tests setting and getting decision text properties
     */
    @IsTest
    static void testDecisionTextProperties() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        decision.klagetekst = 'Klage text content';
        decision.vilkaartekst = 'Vilkår text content';
        decision.githubtekst = 'GitHub text content';
        decision.webTilgangtekst = 'Web access text content';
        decision.vedtaksbegrunnelse = 'Decision justification';
        Test.stopTest();

        System.assertEquals('Klage text content', decision.klagetekst, 'Complaint text should be set');
        System.assertEquals('Vilkår text content', decision.vilkaartekst, 'Terms text should be set');
        System.assertEquals('GitHub text content', decision.githubtekst, 'GitHub text should be set');
        System.assertEquals('Web access text content', decision.webTilgangtekst, 'Web access text should be set');
        System.assertEquals('Decision justification', decision.vedtaksbegrunnelse, 'Decision justification should be set');
    }

    /**
     * @description Tests setting and getting date properties
     */
    @IsTest
    static void testDecisionDateProperties() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        Date testDate = Date.today();
        decision.opprettelseDato = testDate.format();
        decision.vedtaksdato = testDate;
        Test.stopTest();

        System.Assert.isNotNull(decision.opprettelseDato, 'Creation date should be set');
        System.assertEquals(testDate, decision.vedtaksdato, 'Decision date should be set');
    }

    /**
     * @description Tests setting and getting numeric properties
     */
    @IsTest
    static void testDecisionNumericProperties() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        decision.webTilgang = 1;
        Test.stopTest();

        System.assertEquals(1, decision.webTilgang, 'Web access numeric value should be set');
    }

    /**
     * @description Tests multiple decision instances independence
     */
    @IsTest
    static void testMultipleDecisionInstances() {
        Test.startTest();
        AAREG_ApplicationDecision decision1 = new AAREG_ApplicationDecision();
        decision1.vedtaksId = 'ID1';
        decision1.vedtaksNr = 'NUM1';

        AAREG_ApplicationDecision decision2 = new AAREG_ApplicationDecision();
        decision2.vedtaksId = 'ID2';
        decision2.vedtaksNr = 'NUM2';
        Test.stopTest();

        System.assertEquals('ID1', decision1.vedtaksId, 'First decision ID should not be affected');
        System.assertEquals('NUM1', decision1.vedtaksNr, 'First decision number should not be affected');
        System.assertEquals('ID2', decision2.vedtaksId, 'Second decision ID should be independent');
        System.assertEquals('NUM2', decision2.vedtaksNr, 'Second decision number should be independent');
    }

    /**
     * @description Tests null values handling
     */
    @IsTest
    static void testDecisionNullValues() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        Test.stopTest();

        System.assertEquals(null, decision.vedtaksId, 'Unset decision ID should be null');
        System.assertEquals(null, decision.status, 'Unset status should be null');
        System.assertEquals(null, decision.klagetekst, 'Unset complaint text should be null');
        System.assertEquals(null, decision.vedtaksdato, 'Unset decision date should be null');
    }

    /**
     * @description Tests all properties can be set together
     */
    @IsTest
    static void testDecisionCompleteDataSet() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        decision.vedtaksId = 'DEC001';
        decision.vedtaksNr = 'VED001';
        decision.status = 'Approved';
        decision.statusProsess = 'Complete';
        decision.soknadsId = 'APP001';
        decision.opprettelseDato = Date.today().format();
        decision.klagetekst = 'Appeal text';
        decision.vilkaartekst = 'Terms text';
        decision.githubtekst = 'GitHub text';
        decision.webTilgangtekst = 'Web text';
        decision.vedtaksbegrunnelse = 'Justification';
        decision.vedtaksdato = Date.today();
        decision.webTilgang = 1;
        Test.stopTest();

        System.assertEquals('DEC001', decision.vedtaksId, 'All properties should retain their values');
        System.assertEquals(1, decision.webTilgang, 'Numeric property should be set');
        System.assertEquals('Approved', decision.status, 'Status should maintain value');
    }

    /**
     * @description Tests property modification after initial setting
     */
    @IsTest
    static void testDecisionPropertyModification() {
        Test.startTest();
        AAREG_ApplicationDecision decision = new AAREG_ApplicationDecision();
        decision.status = 'Pending';
        System.assertEquals('Pending', decision.status, 'Status should initially be Pending');

        decision.status = 'Approved';
        Test.stopTest();

        System.assertEquals('Approved', decision.status, 'Status should be updated to Approved');
    }
}
