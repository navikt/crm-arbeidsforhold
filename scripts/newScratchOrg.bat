echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.169"
call sfdx force:package:install --package 04t7U000000TqIuQAK -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-integration ver. 0.84"
call sfdx force:package:install --package 04t7U000000TqFHQA0 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-access-control ver. 0.102"
call sfdx force:package:install --package 04t7U000000Tq8LQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-timeline ver. 1.15"
call sfdx force:package:install --package 04t7U000000TpOcQAK -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-community-base ver. 0.71"
call sfdx force:package:install --package 04t7U000000TqLFQA0 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-email-scheduling ver. 1.6"
call sfdx force:package:install --package 04t2o000000yRSSAA2 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-journal-utilities ver. 0.17"
call sfdx force:package:install --package 04t7U000000Tq8BQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-user-notification ver. 0.17"
call sfdx force:package:install --package 04t7U000000TproQAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-flowComponents ver. 0.3"
call sfdx force:package:install --package 04t7U000000Tpf4QAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-henvendelse-base ver. 0.8"
call sfdx force:package:install --package 04t7U000000TpdwQAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-henvendelse ver. 0.80"
call sfdx force:package:install --package 04t7U000000TqGAQA0 -r -k %3 --wait 10 --publishwait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname AAREG_Arbeidsforhold_Saksbehandling

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname AAREG_Arbeidsforhold_Support

echo "Ferdig"
