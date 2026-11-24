import { buildTrail, clearContext, readContext, rememberContext } from 'c/aaregPortalContext';

const BASE = '/aaregisteret/s';
const labels = (trail) => trail.map((item) => item.label);

describe('c-aareg-portal-context', () => {
    beforeEach(() => {
        window.sessionStorage.clear();
    });

    it('shows no trail on the home page or on unknown pages', () => {
        expect(buildTrail(`${BASE}/`, BASE, {})).toEqual([]);
        expect(buildTrail(`${BASE}/ukjent-side`, BASE, {})).toEqual([]);
    });

    it('places a role page directly under the home page', () => {
        const trail = buildTrail(`${BASE}/arbeidsgiver`, BASE, {});

        expect(labels(trail)).toEqual(['Forside', 'Arbeidsgiver']);
        expect(trail[0]).toMatchObject({ href: `${BASE}/`, pageName: 'Home', current: false });
        expect(trail[1].current).toBe(true);
    });

    it('places a service page under the chosen role and keeps the organization on the role link', () => {
        const trail = buildTrail(`${BASE}/mine-soknader`, BASE, {
            roleKey: 'Employer',
            organizationNumber: '889640782'
        });

        expect(labels(trail)).toEqual(['Forside', 'Arbeidsgiver', 'Mine søknader']);
        expect(trail[1]).toMatchObject({
            href: `${BASE}/arbeidsgiver?org=889640782`,
            pageName: 'Arbeidsgiver__c',
            state: { org: '889640782' }
        });
    });

    it('keeps the chosen organization name only while the organization number stays the same', () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '889640782', organizationName: 'Nav Oslo' });
        expect(readContext().organizationName).toBe('Nav Oslo');

        rememberContext({ organizationNumber: '910000001' });

        expect(readContext()).toEqual({ roleKey: 'Employer', organizationNumber: '910000001' });
    });

    it('falls back to the home page when no role has been chosen', () => {
        expect(labels(buildTrail(`${BASE}/min-profil`, BASE, {}))).toEqual(['Forside', 'Min profil']);
    });

    it('places detail pages under their overview without showing record data', () => {
        const trail = buildTrail(`${BASE}/application/a0X000000000001/soknad-ola`, BASE, { roleKey: 'Partner' });

        expect(labels(trail)).toEqual(['Forside', 'Samarbeidspartner / fullmektig', 'Mine søknader', 'Søknad']);
        expect(trail[3]).toMatchObject({ current: true });
    });

    it('remembers the role and organization for the session', () => {
        rememberContext({ roleKey: 'Employer' });
        rememberContext({ organizationNumber: '889640782' });

        expect(readContext()).toEqual({ roleKey: 'Employer', organizationNumber: '889640782' });

        rememberContext({ roleKey: 'Private' });
        expect(readContext()).toEqual({ roleKey: 'Private' });

        clearContext();
        expect(readContext()).toEqual({});
    });

    it('ignores unknown roles and malformed organization numbers', () => {
        rememberContext({ roleKey: 'Hacker', organizationNumber: '12' });

        expect(readContext()).toEqual({});
    });
});
