# P360 Objects

Denne mappa inneheld P360-relaterte custom objects og custom metadata types.

Objekt her skal støtte arkiveringsstatus, P360-referansar, teknisk sporbarheit, kodeverk eller annan metadata som primært høyrer til P360-integrasjonen.

## Ansvar

Objekt her kan brukast til:

- lagring av P360-referansar
- arkiveringsstatus
- teknisk integrasjonstilstand
- correlation ID
- P360-kodeverk
- sporbarheit mellom Salesforce og P360
- operasjonell oppfølging

## Skal ikkje

Objekt her skal ikkje:

- eige generell Application-, Agreement- eller Decision-data
- duplisere data som eigentleg høyrer heime i Aa-registeret-domenet
- lagre dokumentinnhald dersom dette ikkje er eksplisitt avklart
- lagre sensitiv informasjon utan konkret behov

## Typiske objekt

```text
P360_Archive_Request__c
P360_Archive_Document__c
P360_Integration_Log__c
P360_Code_Table_Value__mdt
```

## Namnestandard

Bruk `P360_` for objekt og metadata types som primært høyrer til P360-integrasjonen.

Eksempel:

```text
P360_Archive_Request__c
P360_Code_Table_Value__mdt
```

## Felt

Felt på P360-objekt bør vere eksplisitte og støtte sporbarheit.

Typiske felt:

```text
P360_Case_Number__c
P360_Document_Number__c
P360_External_Id__c
Archive_Status__c
Correlation_Id__c
Last_Error_Message__c
```
