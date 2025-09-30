public without sharing class AAREG_CommunityUtils {
    @AuraEnabled
    public static AltinnCalloutService.AltinnRightsResponse getUserRights(
        String userId,
        String organizationNumber,
        String serviceCode
    ) {
        String serviceCodeNew;
        User currentUser = [SELECT Id, Contact.Account.INT_PersonIdent__c FROM User WHERE Id = :userId];
        AltinnCalloutService altinn = new AltinnCalloutService();

        //TODO: Remove this when Altinn version 3 is fully rolled out
        // This is a temporary fix to ensure that the service resource are correct
        // for the rights returned by Altinn version 3.
        if (new FeatureToggleBase().isFeatureEnabled('Altinn_Version_3', FeatureToggle.ToggleType.FEATURE_FLAG)) {
            if (serviceCode == '5719') {
                serviceCodeNew = 'nav_arbeidsforhold_aa-registeret-sok-tilgang';
            } else if (serviceCode == '5441') {
                serviceCodeNew = 'nav_arbeidsforhold_aa-registeret-brukerstotte';
            }
        } else {
            serviceCodeNew = serviceCode;
        }
        System.debug('getUserRights - serviceCodeNew: ' + serviceCodeNew);
        AltinnCalloutService.AltinnRightsResponse response = altinn.getRights(
            //currentUser.Contact.Account.INT_PersonIdent__c,
            //organizationNumber,
            '08879198748',
            '313199770',
            serviceCodeNew
        );

        // TODO: Remove this when Altinn version 3 is fully rolled out
        // This is a temporary fix to ensure that the service codes are correct
        // for the rights returned by Altinn version 2.
        if (new FeatureToggleBase().isFeatureEnabled('Altinn_Version_3', FeatureToggle.ToggleType.FEATURE_FLAG)) {
            for (AltinnCalloutService.Right right : response.rights) {
                if (right.Resource == 'nav_arbeidsforhold_aa-registeret-sok-tilgang') {
                    right.ServiceCode = '5719';
                } else if (right.Resource == 'nav_arbeidsforhold_aa-registeret-brukerstotte') {
                    right.ServiceCode = '5441';
                    right.ServiceEditionCode = '2';
                }
            }
        }

        System.debug('getUserRights - Response from Altinn: ' + JSON.serializePretty(response));

        return response;
    }
}
