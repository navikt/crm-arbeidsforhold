/**
 * Wrapper class used by AAREG_ApplicationInternalController to send related-contact
 * data to the internal application LWC.
 *
 * @author Ann Kristin Olsen
 * @since November 2025
 * @group AAREG Internal Application
 */
public with sharing class AAREG_RelatedContactInternal {
    @AuraEnabled
    public String KontaktId { get; set; }
    @AuraEnabled
    public String KontaktNavn { get; set; }
    @AuraEnabled
    public String KontaktEpost { get; set; }
    @AuraEnabled
    public String KontaktTelefon { get; set; }
    @AuraEnabled
    public Boolean AvtaleVarsel { get; set; }
    @AuraEnabled
    public Boolean EndringsVarsel { get; set; }
    @AuraEnabled
    public Boolean FeilmeldingsVarsel { get; set; }
    @AuraEnabled
    public Boolean SikkerhetsVarsel { get; set; }
    @AuraEnabled
    public String SoknadsId { get; set; }
}
