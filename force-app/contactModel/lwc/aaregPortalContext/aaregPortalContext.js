const STORAGE_KEY = 'aareg.portal.context';
const ORGANIZATION_NUMBER = /^\d{9}$/;

export const ROLES = {
    Employer: { label: 'Arbeidsgiver', pageName: 'Arbeidsgiver__c', path: 'arbeidsgiver' },
    Partner: { label: 'Samarbeidspartner / fullmektig', pageName: 'Samarbeidspartner__c', path: 'samarbeidspartner' },
    Private: { label: 'Privatperson / arbeidstaker', pageName: 'Privatperson__c', path: 'privatperson' }
};

const HOME = { label: 'Forside', pageName: 'Home', path: '' };

// parent: 'role' = the remembered role page (home when none), otherwise a key in PAGES.
const PAGES = {
    'min-profil': { label: 'Min profil', pageName: 'Min_Profil__c', parent: 'role' },
    'mine-soknader': { label: 'Mine søknader', pageName: 'custom_mine_soknader__c', parent: 'role' },
    'ny-soknad-aa-registret': { label: 'Ny søknad', pageName: 'custom_ny_soknad_aa_registret__c', parent: 'role' },
    'mine-avtaler': { label: 'Mine avtaler', pageName: 'Mine_Avtaler__c', parent: 'role' },
    'mine-meldinger': { label: 'Mine meldinger', pageName: 'Mine_Meldinger__c', parent: 'role' },
    'ny-melding': { label: 'Ny melding', pageName: 'Ny_Melding__c', parent: 'role' },
    application: { label: 'Søknad', parent: 'mine-soknader' },
    agreement: { label: 'Avtale', parent: 'mine-avtaler' },
    thread: { label: 'Melding', parent: 'mine-meldinger' }
};

const ROLE_BY_PATH = Object.fromEntries(Object.entries(ROLES).map(([roleKey, role]) => [role.path, roleKey]));

function sanitize(context) {
    const clean = {};
    if (ROLES[context?.roleKey]) {
        clean.roleKey = context.roleKey;
    }
    if (ORGANIZATION_NUMBER.test(context?.organizationNumber ?? '')) {
        clean.organizationNumber = context.organizationNumber;
    }
    return clean;
}

export function readContext() {
    try {
        return sanitize(JSON.parse(window.sessionStorage.getItem(STORAGE_KEY) ?? '{}'));
    } catch (error) {
        return {};
    }
}

export function rememberContext(update) {
    const current = readContext();
    const roleChanged = update.roleKey !== undefined && update.roleKey !== current.roleKey;
    const next = sanitize(
        roleChanged ? { roleKey: update.roleKey, ...pickOrganization(update) } : { ...current, ...update }
    );
    try {
        window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch (error) {
        // Storage can be unavailable (private mode); the trail then falls back to the home page.
    }
    return next;
}

function pickOrganization(update) {
    return update.organizationNumber ? { organizationNumber: update.organizationNumber } : {};
}

export function clearContext() {
    try {
        window.sessionStorage.removeItem(STORAGE_KEY);
    } catch (error) {
        // Nothing to clear when storage is unavailable.
    }
}

function link(basePath, entry, path, state) {
    const query = state?.org ? `?org=${state.org}` : '';
    return {
        key: entry.pageName ?? path,
        label: entry.label,
        pageName: entry.pageName,
        state: state ?? {},
        href: `${basePath}/${path}${query}`,
        current: false
    };
}

function roleItem(basePath, context) {
    const role = ROLES[context.roleKey];
    if (!role) {
        return undefined;
    }
    const state =
        context.organizationNumber && context.roleKey !== 'Private' ? { org: context.organizationNumber } : {};
    return link(basePath, role, role.path, state);
}

function ancestors(basePath, pageKey, context) {
    const page = PAGES[pageKey];
    if (page.parent === 'role') {
        const role = roleItem(basePath, context);
        return role ? [role] : [];
    }
    return [...ancestors(basePath, page.parent, context), link(basePath, PAGES[page.parent], page.parent)];
}

/**
 * Builds the breadcrumb trail for the current community page.
 * Labels are fixed page names only; record names and organization names are never included.
 */
export function buildTrail(pathname, basePath, context) {
    const relative = (pathname ?? '').startsWith(basePath) ? pathname.slice(basePath.length) : (pathname ?? '');
    const segment = relative.split('/').filter(Boolean)[0];
    const home = link(basePath, HOME, '');
    let trail;
    if (ROLE_BY_PATH[segment]) {
        const role = ROLES[ROLE_BY_PATH[segment]];
        trail = [home, link(basePath, role, role.path)];
    } else if (PAGES[segment]) {
        trail = [home, ...ancestors(basePath, segment, sanitize(context)), link(basePath, PAGES[segment], segment)];
    } else {
        return [];
    }
    trail[trail.length - 1].current = true;
    return trail;
}

/** Returns the site URL for a named community page, or the home page when the name is unknown. */
export function hrefFor(basePath, pageName) {
    const role = Object.values(ROLES).find((candidate) => candidate.pageName === pageName);
    if (role) {
        return `${basePath}/${role.path}`;
    }
    const path = Object.keys(PAGES).find((key) => PAGES[key].pageName === pageName);
    return `${basePath}/${path ?? ''}`;
}
