/**
 * Wrapper class used by AAREG_MyAgreementsController to send agreement data to LWC.
 * This class encapsulates agreement data and related contact information for external interfaces.
 *
 * @author AAREG Team
 * @version 66
 * @group
 */
public class AAREG_Agreement {
    /*
     * Wrapper class used by AAREG_MyAgreementsController to send data to LWC
     **/
    /** Internal agreement record Id. */
    @AuraEnabled
    public String avtaleId { get; set; }
    /** Agreement creation date. */
    @AuraEnabled
    public DateTime avtaleDato { get; set; }
    /** Agreement number. */
    @AuraEnabled
    public String avtaleNummer { get; set; }
    /** Application (søknad) number. */
    @AuraEnabled
    public String soknadsNummer { get; set; }

    /** Indicates whether API access is granted. */
    @AuraEnabled
    public Boolean apiTilgang { get; set; }
    /** Indicates whether data extract (uttrekk) is granted. */
    @AuraEnabled
    public Boolean uttrekk { get; set; }
    /** Indicates whether web access is granted. */
    @AuraEnabled
    public Boolean webTilgang { get; set; }

    /** Consumer Id. */
    @AuraEnabled
    public String konsumentId { get; set; }
    /** Consumer name. */
    @AuraEnabled
    public String konsumentNavn { get; set; }
    /** Consumer contact person name. */
    @AuraEnabled
    public String konsumentKontaktNavn { get; set; }
    /** Consumer organization number. */
    @AuraEnabled
    public String konsumentOrganisasjonsnummer { get; set; }
    /** Consumer address. */
    @AuraEnabled
    public String konsumentAdresse { get; set; }
    /** Consumer city. */
    @AuraEnabled
    public String konsumentPoststed { get; set; }
    /** Consumer postal code. */
    @AuraEnabled
    public String konsumentPostnummer { get; set; }
    /** Consumer email. */
    @AuraEnabled
    public String konsumentEpost { get; set; }
    /** Data processor name. */
    @AuraEnabled
    public String databehandlerNavn { get; set; }
    /** Data processor organization number. */
    @AuraEnabled
    public String databehandlerOrganisasjonsnummer { get; set; }
    /** Organization type. */
    @AuraEnabled
    public String organisasjonsType { get; set; }

    /** Case owner (sakseier) for the agreement. */
    @AuraEnabled
    public String sakseier { get; set; }
    /** Current status of the agreement. */
    @AuraEnabled
    public String status { get; set; }
}
