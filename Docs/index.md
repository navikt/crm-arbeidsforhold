# Arbeidsforhold system documentation

This package contains Salesforce apps that support the work NAV does around the AA register. The solution was developed by Team Arbeidsforhold and includes, among other things, Experience Cloud and the dialogue solution from NKS, support, case management, applications and agreements.

## Access / Users type
There are four types of arbeidsforhold users in NAV as per now. 
- Case handler (internal user)
- Support (internal user)
- Community user
- Dialog

And depending on the type of user, access to arbeidsforhold app is provided.

### Casehandler Users:

Casehandler users are basically assigned permissions defined in permission set "AAREG Arbeidsforhold Saksbehandling", and are assigned to app "Arbeidsforhold"

When the casehandler user logs into Arbeidsforhold app, he is  basically shown five tabs
- Home (This tab is basically the entry page,  this page displays application statistics, list of applications case handler is working, tasks and events scheduled for the day). It also lets user to create a new application, change owner for the application, etc..
- Application (This tab lets the user see a list of all applications in the system. It also lets user to create a new application, change owner for the application etc.).
- Agreement (This tab lets the user see a list of all agreements in the system. It also lets user to create a new agreement, change owner for the agreement etc..).
- Reports (This tab displays all the available reports and lets the user generate different reports).
- Dashboards (This tab displays all the available dashbaords and lets the user see statistics defined in the reports related to them).

### Support Users:

Support users are basically assigned permissions defined in permission set "AAREG Arbeidsforhold Support", and are assigned to app "Arbeidsforhold Henvendelse"

When the Support user logs into Arbeidsforhold Henvendelse app, he is  basically shown one Home tab, but still has the possibility to navigate to five other screens (Inquiries, Accounts, Contacts, Reports, Dashboard) using a drop down menu.
- Home (This tab is basically the entry page,  this page displays support cases statistics, list of support cases case handler is working on,). It also lets user to create a new support case.
- Inquiries (This tab lets the user see a list of all user owned inquiries/ all inquiries in the system.) It also lets user to create a new inquiries.
- Account (This tab lets the user see a list of all accounts in the system.) It also lets user to create a new account, could be of type Business / private/ Employer.
- Contact (This tab lets the user see a list of all contacts in the system.) It also lets user to create a new contact connected to an account. An account can also be created as a part of this process.
- Reports (This tab displays all the available reports and lets the user generate different reports).
- Dashboards (This tab displays all the available dashbaords and lets the user see statistics defined in the reports related to them).

### Community user (experience cloud):

Support users are basically assigned permissions defined in permission set "AAREG Community Permission", and are assigned to app "Min Side - RbukerStætte og søknad om tilgang til AA-registeret"

When the community user logs into this app, he is basically shown one Home tab but still has the possibility to navigate to few other screens to look exisiting agreements, applications, inquiries and to let him create these as well.
- Home (this tab lets the user to create a new application for the organizations where he is access to).In addition to this, there are sections to choose a different organization, display user owned applications, agreements, inquiries and messages, etc.
- Other pages in the drop down menu are basically used as part of the options given on the home page.

