#!/bin/bash
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

ORG_ALIAS="arbeidsforhold"


echo ""
echo "Installing crm-arbeidsforhold scratch org ($ORG_ALIAS)"
echo ""

echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u $ORG_ALIAS &> /dev/null
echo ""

echo "Creating scratch org..." && \
sfdx force:org:create -s -f config/project-scratch-def.json -d 7 -a $ORG_ALIAS && \
echo "" && \

echo "Installing dependencies..."
secret=$npm_config_key
keys="" && for p in $(jq '.packageAliases | keys[]' sfdx-project.json -r); do keys+=$p":"$secret" "; done 
sfdx sfpowerkit:package:dependencies:install -u $ORG_ALIAS -r -a -w 60 -k "${keys}"
echo ""

echo "Pushing metadata..."
sfdx force:source:push
echo ""

echo "Publishing Aareg site..."
sfdx force:community:publish -n "Aa-registret" 
echo ""

echo "Assigning permissions..."
sfdx force:user:permset:assign -n AAREG_Arbeidsforhold_Saksbehandling
sfdx force:user:permset:assign -n AAREG_Arbeidsforhold_Support
sfdx force:user:permset:assign -n AAREG_CommunityPermission
echo ""


echo "Activating Mocks..."
sfdx force:apex:execute -f ./scripts/apex/activateMock.cls
echo ""

echo "Opening org..." && \
sfdx force:org:open
echo ""


EXIT_CODE="$?"
echo ""

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE