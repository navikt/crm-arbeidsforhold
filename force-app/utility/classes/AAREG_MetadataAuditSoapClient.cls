/**
 * Reads supported non-ApexClass metadata through the Salesforce Metadata API SOAP endpoint.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-12
 * @group AAREG Utility
 */
public with sharing class AAREG_MetadataAuditSoapClient {
    private static final String SOAP_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String METADATA_NAMESPACE = 'http://soap.sforce.com/2006/04/metadata';
    private static final String INSTANCE_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';
    private static final String API_VERSION = '67.0';

    /**
     * Reads one non-ApexClass Metadata API component without returning metadata payloads.
     * @param metadataType Metadata API type to read.
     * @param fullName Exact Metadata API fullName for the component.
     * @param sessionId Current caller session ID used only in the SOAP SessionHeader.
     * @return Sanitized existence result; SOAP and transport errors remain UNKNOWN.
     */
    public static Map<String, String> readComponent(String metadataType, String fullName, String sessionId) {
        try {
            HttpResponse response = sendReadRequest(metadataType, fullName, sessionId);
            if (response.getStatusCode() != 200) {
                String soapFaultCode = extractSoapFaultCode(response.getBody());
                String errorCode = soapFaultCode == null ? 'HTTP_' + response.getStatusCode() : soapFaultCode;
                return result('UNKNOWN', errorCode);
            }
            if (String.isBlank(response.getBody()) || response.getBody().length() > 1000000) {
                return result('UNKNOWN', 'RESPONSE_EMPTY_OR_TOO_LARGE');
            }
            return parseResponse(fullName, response.getBody());
        } catch (System.Exception error) {
            return result('UNKNOWN', 'REQUEST_OR_RESPONSE_FAILED');
        }
    }

    private static HttpResponse sendReadRequest(String metadataType, String fullName, String sessionId) {
        Dom.Document document = createRequestDocument(metadataType, fullName, sessionId);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/' + API_VERSION);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('SOAPAction', '""');
        request.setTimeout(10000);
        request.setBody(document.toXmlString());
        return new Http().send(request);
    }

    private static Dom.Document createRequestDocument(String metadataType, String fullName, String sessionId) {
        Dom.Document document = new Dom.Document();
        Dom.XmlNode envelope = document.createRootElement('Envelope', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode header = envelope.addChildElement('Header', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode sessionHeader = header.addChildElement('SessionHeader', METADATA_NAMESPACE, 'met');
        sessionHeader.addChildElement('sessionId', METADATA_NAMESPACE, 'met').addTextNode(sessionId);
        Dom.XmlNode body = envelope.addChildElement('Body', SOAP_NAMESPACE, 'soapenv');
        Dom.XmlNode operation = body.addChildElement('readMetadata', METADATA_NAMESPACE, 'met');
        operation.addChildElement('type', METADATA_NAMESPACE, 'met').addTextNode(metadataType);
        operation.addChildElement('fullNames', METADATA_NAMESPACE, 'met').addTextNode(fullName);
        return document;
    }

    private static Map<String, String> parseResponse(String fullName, String responseBody) {
        Dom.Document document = new Dom.Document();
        document.load(responseBody);
        Dom.XmlNode body = document.getRootElement().getChildElement('Body', SOAP_NAMESPACE);
        if (body == null) {
            return result('UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        if (body.getChildElement('Fault', SOAP_NAMESPACE) != null) {
            String faultCode = extractSoapFaultCode(responseBody);
            return result('UNKNOWN', faultCode == null ? 'SOAP_FAULT' : faultCode);
        }
        Dom.XmlNode response = body.getChildElement('readMetadataResponse', METADATA_NAMESPACE);
        Dom.XmlNode readResult = response == null ? null : response.getChildElement('result', METADATA_NAMESPACE);
        return parseRecord(fullName, readResult);
    }

    private static Map<String, String> parseRecord(String fullName, Dom.XmlNode readResult) {
        if (readResult == null || readResult.getChildElements().size() != 1) {
            return result('UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        Dom.XmlNode record = readResult.getChildElements()[0];
        if (record.getName() != 'records' || record.getNamespace() != METADATA_NAMESPACE) {
            return result('UNKNOWN', 'UNEXPECTED_RESPONSE');
        }
        String nilValue = record.getAttribute('nil', INSTANCE_NAMESPACE);
        if (new Set<String>{ 'true', '1' }.contains(nilValue)) {
            return result('NOT_FOUND', null);
        }
        Dom.XmlNode nameNode = record.getChildElement('fullName', METADATA_NAMESPACE);
        return nameNode != null && fullName.equals(nameNode.getText())
            ? result('FOUND', null)
            : result('UNKNOWN', 'NAME_MISMATCH_OR_MISSING');
    }

    private static String extractSoapFaultCode(String responseBody) {
        if (String.isBlank(responseBody) || responseBody.length() > 1000000) {
            return null;
        }
        try {
            Dom.Document document = new Dom.Document();
            document.load(responseBody);
            Dom.XmlNode body = document.getRootElement().getChildElement('Body', SOAP_NAMESPACE);
            Dom.XmlNode fault = body == null ? null : body.getChildElement('Fault', SOAP_NAMESPACE);
            Dom.XmlNode faultCode = fault == null ? null : fault.getChildElement('faultcode', SOAP_NAMESPACE);
            if (faultCode == null || String.isBlank(faultCode.getText())) {
                return null;
            }
            String code = faultCode.getText().substringAfterLast(':').toUpperCase();
            return Pattern.compile('^[A-Z0-9_]{1,80}$').matcher(code).matches() ? 'SOAP_' + code : null;
        } catch (System.Exception error) {
            return null;
        }
    }

    private static Map<String, String> result(String status, String errorCode) {
        return new Map<String, String>{ 'status' => status, 'errorCode' => errorCode };
    }
}
