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

export async function resolveDecisionAvailability(applications, getDecisionPDF) {
    const rows = applications || [];

    return Promise.all(
        rows.map(async (application) => {
            const disableApplication = !['Venter på svar', 'Utkast'].includes(application.Status__c);

            if (application.Status__c !== 'Avslag') {
                return {
                    ...application,
                    decisionUrl: null,
                    disableButton: true,
                    disableApplication
                };
            }

            try {
                const url = await getDecisionPDF({ applicationId: application.Id });
                return {
                    ...application,
                    decisionUrl: url || null,
                    disableButton: !url,
                    disableApplication
                };
            } catch (error) {
                return {
                    ...application,
                    decisionUrl: null,
                    disableButton: true,
                    disableApplication
                };
            }
        })
    );
}

export function buildDecisionUrl(siteOrigin, urlPath) {
    if (siteOrigin === 'https://navdialog--sit2.sandbox.my.site.com') {
        return siteOrigin + '/aaregisteret' + urlPath;
    }

    return siteOrigin + urlPath;
}
