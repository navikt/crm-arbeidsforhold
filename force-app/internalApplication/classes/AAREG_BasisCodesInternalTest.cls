@IsTest
public class AAREG_BasisCodesInternalTest {
    @IsTest
    static void wrapper_properties_are_settable() {
        AAREG_BasisCodesInternal w = new AAREG_BasisCodesInternal();

        w.KodeverkId = 'KB1';
        w.KodeverkNummer = '001';
        w.SoknadsId = 'a0A000000000001';
        w.OrganisasjonsType = 'County';
        w.AndreHjemmel = 'Other legal basis';
        w.AndreFormaal = 'Other purpose';
        w.Hjemmel = 'Legal basis';
        w.Formaal = 'Purpose';
        w.Behandlingsgrunnlag = 'Processing basis';
        w.APITilgang = true;
        w.Uttrekk = false;
        w.WebTilgang = true;
        w.VedtaksDetailId = 'a0D000000000001';
        w.VedtaksDetailNr = 'VD-1';
        w.VedtaksNr = 'V-1';
        w.Status = 'Approved';
        w.Vedtaksbegrunnelse = 'Reason';
        w.BehandlingsgrunnlagGodkjent = true;

        System.assertEquals('KB1', w.KodeverkId);
        System.assertEquals('001', w.KodeverkNummer);
        System.assertEquals('a0A000000000001', w.SoknadsId);
        System.assertEquals('County', w.OrganisasjonsType);
        System.assertEquals('Other legal basis', w.AndreHjemmel);
        System.assertEquals('Other purpose', w.AndreFormaal);
        System.assertEquals('Legal basis', w.Hjemmel);
        System.assertEquals('Purpose', w.Formaal);
        System.assertEquals('Processing basis', w.Behandlingsgrunnlag);
        System.assertEquals(true, w.APITilgang);
        System.assertEquals(false, w.Uttrekk);
        System.assertEquals(true, w.WebTilgang);
        System.assertEquals('a0D000000000001', w.VedtaksDetailId);
        System.assertEquals('VD-1', w.VedtaksDetailNr);
        System.assertEquals('V-1', w.VedtaksNr);
        System.assertEquals('Approved', w.Status);
        System.assertEquals('Reason', w.Vedtaksbegrunnelse);
        System.assertEquals(true, w.BehandlingsgrunnlagGodkjent);
    }
}
