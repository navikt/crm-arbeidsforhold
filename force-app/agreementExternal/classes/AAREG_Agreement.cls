/**
 * @description Wrapper class used by AAREG_AgreementController to send agreement data to LWC.
 */
public class AAREG_Agreement {
    /*
     * wrapperclass used by AAREG_MyAgreementController to send data to LWC
     **/
    /** @description Internal agreement record Id. */
    @AuraEnabled public String avtaleId { get; set; }
    /** @description Agreement creation date. */    
    @AuraEnabled public DateTime avtaleDato { get; set; }
    /** @description Agreement number. */
    @AuraEnabled public String avtaleNummer { get; set; }
    /** @description Application (søknad) number. */
    @AuraEnabled public String soknadsNummer { get; set; }

    /** @description Indicates whether API access is granted. */
    @AuraEnabled public Boolean apiTilgang { get; set; }
    /** @description Indicates whether data extract (uttrekk) is granted. */
    @AuraEnabled public Boolean uttrekk { get; set; }
    /** @description Indicates whether web access is granted. */
    @AuraEnabled public Boolean webTilgang { get; set; }

    /** @description Consumer Id. */
    @AuraEnabled public String konsumentId { get; set; }
    /** @description Consumer name. */
    @AuraEnabled public String konsumentNavn { get; set; }
    /** @description Consumer contact person name. */
    @AuraEnabled public String konsumentKontaktNavn { get; set; }
    /** @description Consumer organization number. */
    @AuraEnabled public String konsumentOrganisasjonsnummer { get; set; }
    /** @description Consumer address. */
    @AuraEnabled public String konsumentAdresse { get; set; }
    /** @description Consumer city. */
    @AuraEnabled public String konsumentPoststed { get; set; }
    /** @description Consumer postal code. */
    @AuraEnabled public String konsumentPostnummer { get; set; }
    /** @description Consumer email. */
    @AuraEnabled public String konsumentEpost { get; set; }
    /** @description Data processor name. */
    @AuraEnabled public String databehandlerNavn { get; set; }
    /** @description Data processor organization number. */
    @AuraEnabled public String databehandlerOrganisasjonsnummer { get; set; }
    /** @description Organization type. */
    @AuraEnabled public String organisasjonsType { get; set; }

    /** @description Case owner (sakseier) for the agreement. */
    @AuraEnabled public String sakseier { get; set; }
    /** @description Current status of the agreement. */
    @AuraEnabled public String status { get; set; }
}