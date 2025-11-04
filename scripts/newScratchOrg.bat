@echo off
setlocal enabledelayedexpansion

REM Set variables
set ORG_ALIAS=crm-arbeidsforhold
set ORG_DURATION=30
set SECRET=%1

echo Cleaning previous scratch org...
call sf org delete scratch --target-org %ORG_ALIAS% --no-prompt 2>NUL

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
echo "Installerer crm-platform-base 291"
call sf force:package:install --package 04tQC0000011Ey1YAE -r --installation-key %1 --wait 4 --publish-wait 4

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
echo "Installerer crm-platform-integration  165"
call sf force:package:install --package 04tQC0000010MKvYAM -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-access-control 162"
call sf force:package:install --package 04tQC000000tlPhYAI -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-thread-view 0.7.0.."
call sf force:package:install --package 04tQC000000nfmnYAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-shared-timeline 1.35.0.."
call sf force:package:install --package 04tQC000000obpBYAQ -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-community-base 131."
call sf force:package:install --package 04tQC000000xdq9YAA -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-email-scheduling 1.6.0."
call sf force:package:install --package 04t2o000000yRSSAA2 -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-journal-utilities 0.52.0.."
call sf force:package:install --package 04tQC000000yDDhYAM -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-shared-user-notification 0.25.0"
call sf force:package:install --package 04tQC000000tKMHYA2 -r --installation-key %1 --wait 4 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-platform-oppgave 0.65.0"
call sf force:package:install --package 04tQC000000rfOPYAY -r --installation-key %1 --wait 5 --publish-wait 4

echo "INSTALLERER"
echo "Installerer crm-henvendelse 0.186.0"
call sf force:package:install --package 04tQC000000y7EjYAI -r --installation-key %1 --wait 5 --publish-wait 4

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start --target-org %ORG_ALIAS% --wait 10

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset -n AAREG_Arbeidsforhold_Saksbehandling

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset -n AAREG_Arbeidsforhold_Support

echo "Ferdig"
