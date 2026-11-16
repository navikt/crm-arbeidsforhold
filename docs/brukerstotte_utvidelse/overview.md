# Overview of the AAREG external user experience extension

## Purpose

This document describes the analysis and specification for extending the current external user experience in crm-arbeidsforhold. The goal is to support new user groups without changing the current behavior for existing company representatives or support users more than necessary.

## Background

The current solution is built around a company-specific context and the existing access model for company representatives. The home page and navigation in AAREG are largely based on the last selected organization number, and access to application data and messages is currently tied to that selection.

The new solution should expand this to also support:

- employers,
- partners / authorized representatives,
- private individuals / employees.

## Decisions that form the basis

1. The first version supports private individuals, employers, and partners.
2. The current solution for company representatives and the current support flow should work as today without regression.
3. `LastUsedOrganization__c` is used only for company representatives.
4. For employers, partners, and private individuals, person-based context is the primary model, while the organization is used as a work context or filter.
5. Private individuals do not need an organization number or organization selection.
6. Employers and partners must either have an organization number or choose an organization on the homepage before continuing.
7. We will limit the number of new components and build a small new entry page on top of the current `aareg_home` model.

## Core principles

1. Preserve the current solution for company representatives.
2. Reuse existing LWC components, Apex classes, and data models where it is natural to do so.
3. Ensure a clear separation between user group, representation context, and actual access.
4. Validate all authorization dependencies on the server side.
5. Avoid introducing new and generic architecture without a concrete need.
6. Use one active organization context per user in the new person-based flows, not multiple simultaneous active organization selections.

## Entry approaches

The solution should support two entry methods:

- The existing `aareg_home` flow for company representatives and current support users.
- A new, small entry page for user-group selection for employers, partners, and private individuals, where the organization number is only required when relevant.
- Direct entry via URL using query parameters for user group and organization number when relevant.

## Draft of desired behavior

- Company representative: can use existing solutions such as application, my applications, my agreements, support, and my messages.
- Support user: has access to support and relevant messages, in line with the current model.
- Employer: receives access to support and personal messages in a person-based context, but not to organization-based application and agreement functions without their own context.
- Partner / authorized representative: receives access to support and personal messages in a person-based context, but not to organization-based application and agreement functions without their own context.
- Private individual: receives access to personal messages and personal functions without an organization number, but not to business-based functions.

## Documentation structure

This document is the overarching framework. The more detailed analyses are in the other documents in this directory:

- current-implementation.md
- proposed-changes.md
- acr-email-handling.md
- implementation-plan.md
- risks-and-testing.md
- open-questions.md

## Scope limitation

This is an analysis and specification phase. No code should be implemented in this phase. The changes are documented only as plans for later development.
