//Global class to allow tracking which area of the SF application that performs an action
global virtual class CRM_ApplicationDomain {
    global enum Domain {
        NKS,
        HOT,
        POAB,
        AAREG
    }

    global Map<Domain, String> domainMap = new Map<Domain, String>{
        Domain.NKS => 'NKS',
        Domain.HOT => 'HOT',
        Domain.POAB => 'POAB',
        Domain.POAB => 'AAREG'
    };
}