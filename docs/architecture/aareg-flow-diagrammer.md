# Grupperte Flow-diagram for Arbeidsforhold / Aa-registeret

Diagramma samlar dei 37 Flow-definisjonane i fire forretningsområde. Dei utfyller [Flow-katalogen](./aareg-flow-katalog.md), som dokumenterer kvar Flow med inngang, sideeffektar og feilbaner.

## Les guide

- Boksar med Flow API-namn viser konkrete Flow-definisjonar.
- Piler viser forretningsmessig samanheng eller record-hending; dei betyr ikkje nødvendigvis at éin Flow kallar den neste.
- Berre piler merkte `Subflow call` viser direkte gjenbruk av subflow.
- `Obsolete`-flytar er viste for å synleggjere historisk kjeldeinnhald, ikkje som aktive baner.
- Kjelda stadfestar struktur og startvilkår; diagramma stadfestar ikkje at kvar handling køyrer feilfritt i org.

## 1. Søknad, saksbehandling og avgjerd

```mermaid
flowchart TD
    Submit[Ekstern søknad blir oppretta] --> AfterInsert[AAREGApplicationAfterInsertPopulateApplicationFields]
    AfterInsert --> NewStatus[Søknad får status New]
    NewStatus --> Populate[AAREG_populateApplicationFieldAfterSubmit]
    NewStatus --> ContactCheck{Kontakt manglar og stadfesting ikkje sendt}
    ContactCheck -->|Ja| Contact[AAREG_createContactSendConfirmation]
    ContactCheck -->|Nei| Casework[Klar for saksbehandling]
    Contact --> Casework
    Populate --> Casework
    Casework --> StatusChange[Saksbehandlar endrar status]
    StatusChange --> StatusFlow[AAREG_applicationChangingStatus]
    StatusChange --> AdditionalInfoCheck{Status Additional Information Required}
    AdditionalInfoCheck -->|Ja| SetAdditionalInfo[updateApplicationStatusOnCasehandlerStatusAdditionalInformationRequired]
    SetAdditionalInfo --> Awaiting[AAREG_sendAwaitingResponseEmailNotification]
    Awaiting --> Reply[Brukar svarar i søknadstråd]
    Reply --> ExternalMessage[AAREG_applicationChangeStatusAfterMessageFromUser]
    ExternalMessage --> Resume[Status tilbake til In Progress]
    Resume --> OwnerNotification[AAREG_applicationNotificationToCasehandler]
    StatusFlow --> InProgress{Søknaden er In Progress}
    InProgress --> OwnerNotification
    InProgress --> Owner[AAREG_Application_update_case_owner]
    InProgress --> Deadline[AAREG_updateDeadlineDate]
    InProgress --> Comment[AAREG_applicationAddInternalComments]
    InProgress --> Suspension[AAREG_addReasonForSuspension]
    InProgress --> CompleteDecision[AAREG_Decision_Completed]
    CompleteDecision --> Outcome{Avgjerdsutfall}
    Outcome -->|Approved eller Approved Partially| Agreement[Opprett avtale]
    Outcome -->|Declined eller Suspension| DecisionNotice[AAREG_sendDecisionEmailNotification]
    Agreement --> DecisionNotice
```

## 2. Avtale og distribusjonstilgang

```mermaid
flowchart TD
    Approved[Godkjend avgjerd] --> DecisionFlow[AAREG_Decision_Completed]
    DecisionFlow --> Agreement[Agreement oppretta]
    Agreement --> Activity[AAREG_agreementLoggActivity]
    Agreement --> AccessCheck{Aktiv avtale med tilgangsval}
    AccessCheck -->|Ja| CreateAccess[AAREG_Agreement_create_distribution_access]
    CreateAccess --> ExternalCreate[Asynkront kall for å opprette distribusjonstilgang]
    Agreement --> Revision[AAREG_Agreement_revision]
    Revision --> RevisionLog[AAREG_agreementRevisionLoggComment]
    Agreement --> Deactivate[AAREG_deactivateAgreement]
    Deactivate --> KeepAccess{Tilgang skal behaldast}
    KeepAccess -->|Ja| Retain[Avtale inaktiv, tilgang står att]
    KeepAccess -->|Nei| Deactivated[Avtale sett til Deactivated]
    Deactivated --> RemoveAccess[AAREG_removeAccessToDistribution]
    RemoveAccess --> ExternalDelete[Asynkront kall for å fjerne distribusjonstilgang]
    Obsolete[AAREG_deactivateAccess - Obsolete og inaktiv]
```

## 3. Henvending, tråd og støtte

```mermaid
flowchart TD
    Inquiry[Inquiry blir oppretta] --> InternalFlag[AAREG_supportSetInternallyFlag]
    Inquiry --> ContactCheck{Contact manglar}
    ContactCheck -->|Ja| Contact[AAREG_createSupportContact]
    ContactCheck -->|Nei| Thread[Thread blir oppretta]
    Contact --> Thread
    Thread --> ThreadAccount[AAREG_SupportThreadUpdateAccountId]
    Thread --> ThreadOwner[AAREG_afterInsertUpdateThreadOwnerId]
    ExternalMessage[Ekstern melding i henvendingstråd] --> CasehandlerNotice[AAREG_SupportSendNotificationToCasehandler]
    Thread --> InternalComment[AAREG_supportAddInternalComments]
    Thread --> NotifyUserAction[Saksbehandlar vel å varsle brukar]
    NotifyUserAction --> NotifyUser[AAREG_SupportSendNotificationToUser]
    Thread --> TypeChanged{Henvendingstype endra}
    TypeChanged -->|Ja, eigd og ikkje New eller Draft| RemoveOwner[AAREG_supportRemoveCaseOwner]
    Thread --> SecurityType{Ny sikkerheitsrelatert henvending}
    SecurityType -->|Ja| SMS[AAREG_supportSendSMSOnTypeSecurity]
    Closed[Inquiry blir Closed] --> Inactive[AAREG_setThreadToInactiveOnInquiryClosed]
    Scheduled[Planlagd opprydding av Draft] --> DeleteDraft[AAREG_deleteDraftInquiriesANDrelatedDocuments]
    Obsolete[AAREG_getObjectTypeName - Obsolete og inaktiv]
```

## 4. Delte subflows og feilhandsaming

```mermaid
flowchart TD
    Caller[Applikasjons-, avtale- eller støtte-Flow] -->|Subflow call| CreateTask[AAREG_subflowCreateTask]
    Caller -->|Subflow call| CreateSMS[AAREG_subflowCreateSMS]
    Caller -->|Fault path| ErrorHandler[AAREG_Handle_Error_Messages]
    Caller -->|Fault path| ShortError[AAREG_Log_And_Disp_Short_Messages]
```

## Ende-til-ende-sekvens: søknad til avgjerd

Sekvensen viser hovudbana frå innsending til avgjerd. P360-arkivering er ikkje del av denne Flow-bana; sjå den separate [P360-kartlegginga](../integrations/p360/kartlegging-av-dagens-flytar.md).

<!-- mermaid-checked: every participant uses `participant Id as "Label"`, no \n in aliases/messages/notes, every alt/opt/loop closed by end, no `:` inside any alias -->

```mermaid
sequenceDiagram
    participant Representative as "Ekstern representant"
    participant Portal as "Experience Cloud"
    participant Controller as "Application controller"
    participant Flows as "Salesforce Flow"
    participant Caseworker as "Saksbehandlar"
    participant Decision as "Avgjerd"
    participant Agreement as "Avtale"
    participant Distribution as "Tilgangsteneste"

    Representative->>Portal: Send inn søknad
    Portal->>Controller: Behandle og lagre søknad
    Controller-->>Portal: Stadfest lagring
    Flows->>Flows: Fyll ut søknadsfelt etter oppretting
    opt Kontakt manglar
        Flows->>Flows: Opprett kontakt og kølegg stadfesting
    end
    Caseworker->>Flows: Endre saksbehandlarstatus
    alt Meir informasjon er naudsynt
        Flows->>Flows: Set ventestatus og kølegg e-post
        Representative->>Portal: Svar i søknadstråd
        Portal->>Flows: Opprett ekstern melding
        Flows->>Flows: Set søknaden tilbake til In Progress
        Flows-)Caseworker: Kølegg saksbehandlarvarsel
    else Saksbehandlar fullfører avgjerd
        Caseworker->>Decision: Registrer avgjerdsutfall
        Decision->>Flows: Fullfør avgjerdsflyt
        alt Godkjend eller delvis godkjend
            Flows->>Agreement: Opprett avtale og avgjerdsdokument
            Flows-)Distribution: Kølegg tilgangsdistribusjon
        else Avslått
            Flows->>Flows: Fullfør søknad utan avtale
        end
    end
```

## Avgrensingar

- Flow-diagramma viser samla forretningsområde, ikkje Salesforce sin fullstendige interne elementgraf for kvar Flow.
- Skjermflytane sine konkrete Lightning Action-/sidebindingar må verifiserast separat.
- Varsling som blir kølagd er ikkje det same som levert e-post eller SMS.
- Fullført Flow/Apex-handling er ikkje bevis på at distribusjonstilgang vart oppretta eller fjerna eksternt.
- Den godkjende org-inventeringa fann 35 aktive og to inaktive Flow-definisjonar. Ingen Flow vart køyrd funksjonelt i denne diagramgjennomgangen.
