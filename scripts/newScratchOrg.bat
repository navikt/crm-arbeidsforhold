echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.147"
call sfdx force:package:install --package 04t7U000000ToQrQAK -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-integration ver. 0.74"
call sfdx force:package:install --package 04t7U000000ToLcQAK -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-access-control ver. 0.83"
call sfdx force:package:install --package 04t7U000000TnyOQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-timeline ver. 1.12"
call sfdx force:package:install --package 04t7U000000TnjxQAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-community-base ver. 0.59"
call sfdx force:package:install --package 04t7U000000Toi7QAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-email-scheduling ver. 1.6.0"
call sfdx force:package:install --package 04t2o000000yRSSAA2 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-journal-utilities ver. 0.13.0"
call sfdx force:package:install --package 04t7U000000ToHfQAK -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-user-notification. 0.6.0"
call sfdx force:package:install --package 04t7U000000TohTQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-shared-flowComponents. 0.1.0"
call sfdx force:package:install --package 04t2o000000yUEnAAM -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-henvendelse. 0.50.0"
call sfdx force:package:install --package 04t7U000000Toc9QAC -r -k %3 --wait 10 --publishwait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname AAREG_Arbeidsforhold_Saksbehandling

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname AAREG_Arbeidsforhold_Support

echo "Ferdig"
