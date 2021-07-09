public class AAREG_WebsakXMLGenerator {
  private String businessUnitId;
  private String businessUnitName;
  private String journalPostStatus; // Bruk J på alle
  private String journalPostType; // I = inngående, U = utgående, X = Ingen
  private String applicationId;
  private String userNavIdent;
  private String organizationName;
  private String organizationNumber;
  private String mailingAddress;
  private String mailingCity;
  private String mailingPostalCode;
  private Date submissionDate;
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

  public AAREG_WebsakXMLGenerator organizationName(String organizationName) {
    this.organizationName = organizationName;
    return this;
  }

  public AAREG_WebsakXMLGenerator organizationNumber(String organizationNumber) {
    this.organizationNumber = organizationNumber;
    return this;
  }

  public AAREG_WebsakXMLGenerator mailingAddress(String mailingAddress) {
    this.mailingAddress = mailingAddress;
    return this;
  }

  public AAREG_WebsakXMLGenerator mailingCity(String mailingCity) {
    this.mailingCity = mailingCity;
    return this;
  }

  public AAREG_WebsakXMLGenerator mailingPostalCode(String mailingPostalCode) {
    this.mailingPostalCode = mailingPostalCode;
    return this;
  }

  public AAREG_WebsakXMLGenerator submissionDate(Date submissionDate) {
    this.submissionDate = submissionDate;
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
    generator.organizationName = this.organizationName;
    generator.organizationNumber = this.organizationNumber;
    generator.mailingAddress = this.mailingAddress;
    generator.mailingCity = this.mailingCity;
    generator.mailingPostalCode = this.mailingPostalCode;
    generator.submissionDate = this.submissionDate;
    generator.documentNameFormat = this.documentNameFormat;
    return generator;
  }

  public String generateXML() {
    Dom.Document doc = new Dom.Document();
    dom.XmlNode rootNode = doc.createRootElement('NOARK.H', null, null);
    dom.XmlNode noArkSak = rootNode.addChildElement('NOARKSAK', null, null);
    dom.xmlNode application = noArkSak.addChildElement('SA.SOKNADSID', null, null).addTextNode(applicationId);
    dom.xmlNode journalPostTab = noArkSak.addChildElement('JOURNALPOST.TAB', null, null);
    dom.xmlNode post = journalPostTab.addChildElement('JOURNALPOST', null, null);
    dom.xmlNode postContent = post.addChildElement('JP.INNHOLD', null, null).addTextNode(getFormattedContentString());
    dom.xmlNode postDate = post.addChildElement('JP.DOKDATO', null, null).addTextNode(formatDateString(submissionDate));
    dom.xmlNode journalPostType = post.addChildElement('JP.DOKTYPE', null, null).addTextNode(journalPostType);
    dom.xmlNode journalPostStatus = post.addChildElement('JP.STATUS', null, null).addTextNode(journalPostStatus);
    dom.xmlNode journalPostNavIdent = post.addChildElement('JP.SB', null, null).addTextNode(userNavIdent);
    dom.xmlNode journalPostUnitId = post.addChildElement('JP.ENHET', null, null).addTextNode(businessUnitId);
    dom.xmlNode journalPostUnitName = post.addChildElement('NAVN', null, null).addTextNode(businessUnitName);
    dom.xmlNode addressTab = post.addChildElement('ADRESSAT.TAB', null, null);
    dom.xmlNode address = addressTab.addChildElement('ADRESSAT', null, null);
    dom.xmlNode orgName = address.addChildElement('NAVN', null, null).addTextNode(organizationName);
    dom.xmlNode orgNumber = address.addChildElement('ORGNR', null, null).addTextNode(organizationNumber);
    dom.xmlNode orgEmail = address.addChildElement('EPOSTADR', null, null);
    dom.xmlNode orgPhone = address.addChildElement('TLF', null, null);
    dom.xmlNode orgStreet = address.addChildElement('ADRESSE', null, null).addTextNode(mailingAddress);
    dom.xmlNode orgAddress = address.addChildElement('POSTADRESSE', null, null);
    orgAddress.addTextNode(formatCityPostalCode(mailingCity, mailingPostalCode));
    dom.XmlNode documentTab = post.addChildElement('DOKVERSJON.TAB', null, null);

    for (String docName : documentNameFormat.keyset()) {
      String fileName = docName;
      String fileFormat = documentNameFormat.get(docName);
      dom.XmlNode documentVersion = documentTab.addChildElement('DOKVERSJON', null, null);
      dom.XmlNode documentFormat = documentVersion.addChildElement('VE.DOKFORMAT', null, null).addTextNode(fileFormat);
      dom.XmlNode documentReference = documentVersion.addChildElement('VE.FILREF', null, null).addTextNode(fileName);
    }
    return doc.toXmlString();
  }

  private String formatDateString(Date input) {
    Datetime dateToFormat = input;
    return dateToFormat.formatGmt('YYYYMMdd');
  }

  private String formatCityPostalCode(String city, String postalCode) {
    return city + ' ' + postalCode;
  }

  private String getFormattedContentString() {
    return 'Soknad AA-registeret-' + applicationId + '-' + organizationNumber;
  }
}
