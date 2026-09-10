export function updateApplicationsWithDecisionState(applications, applicationId, url) {
    return (applications || []).map((application) => {
        if (application.Id !== applicationId) {
            return application;
        }

        return {
            ...application,
            decisionUrl: url || null,
            disableButton: !url
        };
    });
}

export async function resolveDecisionAvailability(applications, getDecisionPDFs) {
    const rows = applications || [];
    const declinedApplicationIds = rows
        .filter((application) => application.Status__c === 'Avslag')
        .map((application) => application.Id);
    let decisionUrlsByApplicationId = {};

    if (declinedApplicationIds.length > 0) {
        try {
            decisionUrlsByApplicationId = (await getDecisionPDFs({ applicationIds: declinedApplicationIds })) || {};
        } catch (error) {
            decisionUrlsByApplicationId = {};
        }
    }

    return rows.map((application) => {
        const disableApplication = !['Venter på svar', 'Utkast'].includes(application.Status__c);

        if (application.Status__c !== 'Avslag') {
            return {
                ...application,
                decisionUrl: null,
                disableButton: true,
                disableApplication
            };
        }

        const url = decisionUrlsByApplicationId[application.Id] || null;
        return {
            ...application,
            decisionUrl: url,
            disableButton: !url,
            disableApplication
        };
    });
}

export function buildDecisionUrl(siteOrigin, urlPath) {
    if (siteOrigin === 'https://navdialog--sit2.sandbox.my.site.com') {
        return siteOrigin + '/aaregisteret' + urlPath;
    }

    return siteOrigin + urlPath;
}
