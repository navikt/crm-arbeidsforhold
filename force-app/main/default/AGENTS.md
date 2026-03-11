# Project Agent Instructions: crm-arbeidsforhold

## Overview
This is a Salesforce project for **Aa-registeret** (Arbeidsgiver- og arbeidstaker registeret). The project uses Experience Cloud for external users and internal Salesforce for case handlers. It manages applications, agreements, decisions, and distribution access for organizations accessing employment data.

---

## Project Structure
force-app/ ├── main/default/ # Core metadata (permission sets, report types, etc.) ├── aareg_AccessExternal/ # External access (Experience Cloud controllers) ├── aareg_ApplicationAgreementExternal/ # External application & agreement logic ├── aareg_ApplicationAgreementInternal/ # Internal application & agreement logic ├── aareg_ApplicationDecisionInternal/ # Decision PDF generation & management ├── aareg_DistributionAccess/ # Distribution access callouts ├── aareg_Utility/ # Shared utilities & test data factory

## Apex Best Practices

### Naming Conventions
- All classes MUST be prefixed with `AAREG_`.
- Controller classes: `AAREG_<Feature>Controller` (e.g., `AAREG_HomeController`).
- Test classes: `AAREG_<ClassName>Test` (e.g., `AAREG_HomeControllerTest`).
- Selector classes: `AAREG_<Object>Selector` (e.g., `AAREG_accountSelector`).
- Wrapper classes: `AAREG_<Purpose>Internal` (e.g., `AAREG_ApplicationInternal`).

### Code Quality Rules
- Always use `with sharing` unless there is a documented reason to use `without sharing`.
- Never hardcode record IDs or org-specific URLs. Use Custom Metadata, Custom Settings, or Custom Labels instead.
- All `@AuraEnabled` methods MUST include proper error handling with `try-catch` blocks.
- Always throw `AuraHandledException` for errors surfaced to LWC components.
- Use `LoggerUtility` for logging errors instead of `System.debug` in production code.

### SOQL & DML Rules
- **Never** place SOQL queries or DML operations inside loops.
- Always bulkify code to handle collections of records.
- Use selective SOQL queries — only query fields that are needed.
- Use `!list.isEmpty()` instead of `list != null` when checking query results.
- Always use `LIMIT` clauses when expecting a single record.

### Exception Handling Pattern
```apex
@AuraEnabled
public static void myMethod(Id recordId) {
    try {
        // Business logic here
    } catch (DmlException e) {
        LoggerUtility logger = new LoggerUtility();
        logger.error('Error message: ' + e.getMessage(), null);
        logger.publish();
        throw new AuraHandledException('User-friendly error message.');
    } catch (Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.error('Unexpected error: ' + e.getMessage(), null);
        logger.publish();
        throw new AuraHandledException('An unexpected error occurred.');
    }
}