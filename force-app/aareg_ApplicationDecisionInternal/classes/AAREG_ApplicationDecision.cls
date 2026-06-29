/**
 * @description Wrapper-klasse brukt av AAREG_ApplicationDecisionController 
 *              for å sende vedtaksdata til LWC.
 * @group AAREG
 */

public with sharing class AAREG_ApplicationDecision {

        @AuraEnabled public String vedtaksId { get; set; }
        @AuraEnabled public String vedtaksNr { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String statusProsess { get; set; }
        @AuraEnabled public String soknadsId { get; set; }
        @AuraEnabled public String opprettelseDato { get; set; }      
        @AuraEnabled public String klagetekst { get; set; }
        @AuraEnabled public String vilkaartekst { get; set; }
        @AuraEnabled public String githubtekst { get; set; } 
        @AuraEnabled public String webTilgangtekst { get; set; }
        @AuraEnabled public String vedtaksbegrunnelse { get; set; }
        @AuraEnabled public Date vedtaksdato { get; set; }
        @AuraEnabled public Decimal webTilgang { get; set; }

        /**
     * @description Tom konstruktør for enkel instansiering.
     */
    public AAREG_ApplicationDecision() {}
}