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

export function buildDecisionUrl(siteOrigin, urlPath) {
    if (siteOrigin === 'https://navdialog--sit2.sandbox.my.site.com') {
        return siteOrigin + '/aaregisteret' + urlPath;
    }

    return siteOrigin + urlPath;
}
