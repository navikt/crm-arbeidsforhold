/**
 * Wrapper class used by AAREG_ApplicationInternalController to send basis-code data
 * to the internal application LWC, and by AAREG_ApplicationDecisionPDFController to
 * send basis-code data to the decision PDF generator.
 *
 * @author Ann Kristin Olsen
 * @since November 2025
 * @group AAREG Internal Application
 */
public with sharing class AAREG_BasisCodesInternal {
    @AuraEnabled
    public String KodeverkId { get; set; }
    @AuraEnabled
    public String KodeverkNummer { get; set; }
    @AuraEnabled
    public String SoknadsId { get; set; }
    @AuraEnabled
    public String OrganisasjonsType { get; set; }
    @AuraEnabled
    public String AndreHjemmel { get; set; }
    @AuraEnabled
    public String AndreFormaal { get; set; }
    @AuraEnabled
    public String Hjemmel { get; set; }
    @AuraEnabled
    public String Formaal { get; set; }
    @AuraEnabled
    public String Behandlingsgrunnlag { get; set; }
    @AuraEnabled
    public Boolean APITilgang { get; set; }
    @AuraEnabled
    public Boolean Uttrekk { get; set; }
    @AuraEnabled
    public Boolean WebTilgang { get; set; }
    @AuraEnabled
    public String VedtaksDetailId { get; set; }
    @AuraEnabled
    public String VedtaksDetailNr { get; set; }
    @AuraEnabled
    public String VedtaksNr { get; set; }
    @AuraEnabled
    public String Status { get; set; }
    @AuraEnabled
    public String Vedtaksbegrunnelse { get; set; }
    @AuraEnabled
    public Boolean BehandlingsgrunnlagGodkjent { get; set; }
}
