---
applyTo: "force-app/**/*.cls"
---

# Salesforce Apex standards

For new or materially changed Apex in the main package:

- Follow the local rules in `force-app/main/default/AGENTS.md` and Nav Platforce naming conventions.
- Use `with sharing` by default. Make any privileged sharing decision explicit in ApexDoc.
- Keep classes cohesive, methods small, names descriptive, and control flow easy to follow. Prefer the simplest design that satisfies the requirement.
- Keep triggers thin and delegate business logic to a handler or service.
- Bulkify all SOQL and DML. Do not query or perform DML inside loops.
- Avoid hardcoded IDs, URLs, credentials, package keys, and personal data. Use existing configuration, Custom Metadata, Custom Labels, Named Credentials, and test factories.
- Protect `@AuraEnabled`, `@InvocableMethod`, REST, and callout boundaries with explicit validation, access checks, error handling, and documented platform behaviour.
- Use ApexDoc for new or materially changed public classes, methods, constructors, properties, interfaces, enums, and significant annotations. Use a one-sentence summary followed by relevant `@param`, `@return`, `@throws`, `@see`, `@since`, or `@deprecated` tags.
- Name tests after business scenarios and expected behaviour. Do not add a `test` prefix to test methods.
- Add or update a focused behavioural test before implementation when an executable test seam exists. Report an authenticated-org blocker for Apex tests instead of claiming a green result.
- Review design changes against Salesforce Well-Architected: Trusted, Easy, and Adaptable. Record important tradeoffs and preserve deployed public contracts.
