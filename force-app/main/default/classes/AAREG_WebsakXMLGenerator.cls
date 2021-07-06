public class AAREG_WebsakXMLGenerator {
  private String businessUnitId;
  private String businessUnitName;
  private String journalPostStatus; // Bruk J på alle
  private String journalPostType; // I = inngående, U = utgående, X = Ingen
  private String applicationId;
  private String userNavIdent;
  private Map<String, String> documentNameFormat;

  public AAREG_WebsakXMLGenerator businessUnitId(String businessUnitId) {
    this.businessUnitId = businessUnitId;
    return this;
  }

  public AAREG_WebsakXMLGenerator businessUnitName(String businessUnitName) {
    this.businessUnitName = businessUnitName;
    return this;
  }

  public AAREG_WebsakXMLGenerator journalPostStatus(String journalPostStatus) {
    this.journalPostStatus = journalPostStatus;
    return this;
  }

  public AAREG_WebsakXMLGenerator journalPostType(String journalPostType) {
    this.journalPostType = journalPostType;
    return this;
  }

  public AAREG_WebsakXMLGenerator applicationId(String applicationId) {
    this.applicationId = applicationId;
    return this;
  }

  public AAREG_WebsakXMLGenerator userNavIdent(String userNavIdent) {
    this.userNavIdent = userNavIdent;
    return this;
  }

  public AAREG_WebsakXMLGenerator documentNameFormat(Map<String, String> documentNameFormat) {
    this.documentNameFormat = documentNameFormat;
    return this;
  }

  public AAREG_WebsakXMLGenerator build() {
    AAREG_WebsakXMLGenerator generator = new AAREG_WebsakXMLGenerator();
    generator.businessUnitId = this.businessUnitId;
    generator.businessUnitName = this.businessUnitName;
    generator.journalPostStatus = this.journalPostStatus;
    generator.journalPostType = this.journalPostType;
    generator.applicationId = this.applicationId;
    generator.userNavIdent = this.userNavIdent;
    generator.documentNameFormat = this.documentNameFormat;

    return generator;
  }

  public String generateXML() {
    XmlStreamWriter writer = new XmlStreamWriter();

    writer.writeStartDocument('UTF-8', '1.0');
    writer.writeStartElement('', 'NOARK.H', '');
    writer.writeStartElement(null, 'NOARKSAK', null);
    writer.writeStartElement('', 'SA.SOKNADSID', '');
    writer.writeCharacters(this.applicationId);
    writer.writeEndElement();
    writer.writeStartElement('', 'JOURNALPOST.TAB', '');
    writer.writeStartElement('', 'JOURNALPOST', '');
    writer.writeStartElement('', 'JP.INNHOLD', '');
    writer.writeCharacters('Soknad AA-registeret'); // add content
    writer.writeEndElement();
    writer.writeStartElement('', 'JP.DOKDATO', '');
    writer.writeCharacters('Formatted Date'); // Add date in correct format
    writer.writeEndElement();
    writer.writeStartElement('', 'JP.DOKTYPE', '');
    writer.writeCharacters(this.journalPostType);
    writer.writeEndElement();
    writer.writeStartElement('', 'JP.STATUS', '');
    writer.writeCharacters(this.journalPostStatus);
    writer.writeEndElement();
    writer.writeStartElement('', 'JP.SB', '');
    writer.writeCharacters(this.userNavIdent);
    writer.writeEndElement();
    writer.writeStartElement('', 'JP.ENHET', '');
    writer.writeCharacters(this.businessUnitId);
    writer.writeEndElement();
    writer.writeStartElement('', 'NAVN', '');
    writer.writeCharacters(this.businessUnitName);
    writer.writeEndElement();
    writer.writeStartElement('', 'ADRESSAT.TAB', '');
    writer.writeStartElement('', 'ADRESSAT', '');
    writer.writeStartElement('', 'NAVN', '');
    writer.writeCharacters('Account Name'); // add account name
    writer.writeEndElement();
    writer.writeStartElement('', 'ORGNR', '');
    writer.writeCharacters('Org number'); // add orgnumber
    writer.writeEndElement();
    writer.writeStartElement('', 'EPOSTADR', '');
    writer.writeEndElement();
    writer.writeStartElement('', 'TLF', '');
    writer.writeEndElement();
    writer.writeStartElement('', 'ADRESSE', '');
    writer.writeCharacters('Address'); // add account address
    writer.writeEndElement();
    writer.writeStartElement('', 'POSTADRESSE', '');
    writer.writeCharacters('City and postal code'); // add postal code and city
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeStartElement('', 'DOKVERSJON.TAB', '');

    for (String docName : documentNameFormat.keyset()) {
      String fileName = docName;
      String fileFormat = documentNameFormat.get(docName);
      writer.writeStartElement('', 'DOKVERSJON', '');
      writer.writeStartElement('', 'VE.DOKFORMAT', '');
      writer.writeCharacters(fileFormat);
      writer.writeEndElement();
      writer.writeStartElement('', 'VE.FILREF', '');
      writer.writeCharacters(fileName);
      writer.writeEndElement();
      writer.writeEndElement();
    }

    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndDocument();

    return writer.getXmlString();
  }
}
