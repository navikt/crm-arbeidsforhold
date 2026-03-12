@echo off
setlocal enabledelayedexpansion

REM Set variables
set ORG_ALIAS=crm-arbeidsforhold
set ORG_DURATION=30
set SECRET=%1

//echo Cleaning previous scratch org...
//call sf org delete scratch --target-org %ORG_ALIAS% --no-prompt 2>NUL

echo "Oppretter scratch org"
call sf org create scratch --alias %ORG_ALIAS% --set-default --definition-file config/project-scratch-def.json --duration-days %ORG_DURATION% --wait 10

call sf force:org:open --target-org %ORG_ALIAS%

echo "INSTALLERER"
echo "Installerer platform-data-model  0.1.2.1"
call sf force:package:install --package 04tQC000000oHLpYAM -r --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer custom-metadata-dao  0.1.2.1"
call sf force:package:install --package 04tQC000000oHKDYA2 -r --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer custom-permission-helper  0.1.2.1"
call sf force:package:install --package 04tQC000000oGw2YAE -r --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer feature-toggle  0.1.3.1"
call sf force:package:install --package 04tQC000000oHP3YAM -r --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-base 29"
call sf force:package:install --package 04tQC0000017zfhYAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-reporting 0.44.0.."
call sf force:package:install --package 04tQC000000xlvlYAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-shared-flowComponents 0.4.0.."
call sf force:package:install --package 04t7U0000008qz4QAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-henvendelse-base 0.36.0.."
call sf force:package:install --package 04tQC000000uSXtYAM -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-integration  171"
call sf force:package:install --package 04tQC000001A8RxYAK -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-access-control 176"
call sf force:package:install --package 04tQC000001A8q9YAC -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-thread-view 0.9.0.."
call sf force:package:install --package 04tQC0000011athYAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-shared-timeline 1.44.0.."
call sf force:package:install --package 04tQC0000019KTZYA2 -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-community-base 140."
call sf force:package:install --package 04tQC0000018OivYAE -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-email-scheduling 1.8.0."
call sf force:package:install --package 04tKB000000Y5TZYA0 -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-journal-utilities 0.55.0.."
call sf force:package:install --package 04tQC0000012pVhYAI -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-shared-user-notification 0.27.0"
call sf force:package:install --package 04tQC0000012h6jYAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-oppgave 0.70.0"
call sf force:package:install --package 04tQC0000018tTNYAY -r --installation-key %1 --wait 5 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-henvendelse 0.199.0"
call sf force:package:install --package 04tQC0000019zbZYAQ -r --installation-key %1 --wait 5 --publish-wait 4

//echo "Dytter kildekoden til scratch org'en"
call sf project deploy start --target-org %ORG_ALIAS% --wait 10

//echo "INSTALLERER"
//echo "Installerer crm-arbeidsforhold 0.297.0 beta35"
//call sf force:package:install --package 04tQC0000013uLFYAY -r --installation-key %1 --wait 5 --publish-wait 4

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset -n AAREG_Arbeidsforhold_Saksbehandling

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset -n AAREG_Arbeidsforhold_Support

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset -n AAREG_CommunityPermission

//echo Inserting test data...
call sf force:data:tree:import -p  dummy-data/Plan.json

echo "Ferdig"
