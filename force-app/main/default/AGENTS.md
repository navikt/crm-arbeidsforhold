# Project Agent Instructions: crm-arbeidsforhold

## Overview

This is a Salesforce project for **Aa-registeret** (Arbeidsgiver- og arbeidstaker registeret). The project uses Experience Cloud for external users and internal Salesforce for case handlers. It manages applications, agreements, decisions, and distribution access for organizations accessing employment data.

---

## Project Structure

force-app/ ├── main/default/ # Core metadata (permission sets, report types, etc.) ├── aareg_AccessExternal/ # External access (Experience Cloud controllers) ├── aareg_ApplicationAgreementExternal/ # External application & agreement logic ├── aareg_ApplicationAgreementInternal/ # Internal application & agreement logic ├── aareg_ApplicationDecisionInternal/ # Decision PDF generation & management ├── aareg_DistributionAccess/ # Distribution access callouts ├── aareg_Utility/ # Shared utilities & test data factory

## Apex Best Practices

Follow Nav Platforce naming conventions and Salesforce ApexDoc guidance for new or materially changed code.

### Naming and Documentation

- Use PascalCase for class names and the established `<Namespace>_<ClassName><Suffix>` shape, for example `AAREG_HomeController`.
- Use verb-first camelCase for methods, such as `getApplicationDetails`.
- Name test classes `<ClassBeingTested>Test` without an underscore before `Test`.
- Name test methods after the business scenario or expected behaviour. Use a readable `given_When_Then` or `should_When` shape and do not add a `test` prefix.
- Use English for Apex and metadata identifiers. Translate user-facing labels to Norwegian through the established metadata translation pattern.
- Use ApexDoc comments (`/** ... */`) for new or materially changed public classes, methods, constructors, properties, interfaces, enums, and significant annotations. Document purpose, sharing/security implications, parameters, return values, exceptions, and platform behaviour where relevant.
- Keep code clean and readable: prefer cohesive classes, small methods, explicit names, shallow control flow, and minimal abstractions.

### Naming Conventions

- All classes MUST be prefixed with `AAREG_`.
- Controller classes: `AAREG_<Feature>Controller` (e.g., `AAREG_HomeController`).
- Test classes: `AAREG_<ClassName>Test` (e.g., `AAREG_HomeControllerTest`).
- Selector classes: `AAREG_<Object>Selector` (e.g., `AAREG_AccountSelector`).
- Wrapper classes: `AAREG_<Purpose>Internal` (e.g., `AAREG_ApplicationInternal`).

### Code Quality Rules

- Always use `with sharing` unless there is a documented reason to use `without sharing`.
- Never hardcode record IDs or org-specific URLs. Use Custom Metadata, Custom Settings, or Custom Labels instead.
- All `@AuraEnabled` methods MUST define explicit, context-appropriate error handling. Use `try-catch` when the method must translate, log, or recover from an exception; do not add blanket catches that hide failures.
- Throw `AuraHandledException` for expected errors that must be surfaced as user-friendly messages to LWC components, while preserving unexpected failures for the established logging and error boundary.
- Use `LoggerUtility` for logging errors instead of `System.debug` in production code.

### Well-Architected Review

For design changes, assess the Salesforce Well-Architected dimensions:

- **Trusted:** secure access, compliant data handling, and reliable failure and recovery behaviour.
- **Easy:** intentional scope, maintainable and readable code, appropriate automation, and understandable user workflows.
- **Adaptable:** resilience, separation of concerns, interoperability, and packageability.

Document important tradeoffs and preserve deployed public contracts. Do not rename existing metadata or public APIs only to correct legacy naming; record that work separately with a migration plan.

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
```
