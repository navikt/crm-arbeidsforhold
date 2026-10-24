# Metadata audit: Execute Anonymous batches

Source: origin/main, commit d399afd8b42acad6d812c5835644d5de070f834d.

91 candidates in 10 batches. No org was contacted during generation.

Run each listed file separately in an explicitly approved org. Do not concatenate batches into one transaction.
The Apex class must already be deployed and its same-org API access configured.
Production execution requires separate approval. UNKNOWN does not mean absent, and no result authorizes deletion.

| Script | Candidates |
| --- | --- |
| [batch-01.apex](batch-01.apex) | 10 |
| [batch-02.apex](batch-02.apex) | 10 |
| [batch-03.apex](batch-03.apex) | 10 |
| [batch-04.apex](batch-04.apex) | 10 |
| [batch-05.apex](batch-05.apex) | 10 |
| [batch-06.apex](batch-06.apex) | 10 |
| [batch-07.apex](batch-07.apex) | 10 |
| [batch-08.apex](batch-08.apex) | 10 |
| [batch-09.apex](batch-09.apex) | 10 |
| [batch-10.apex](batch-10.apex) | 1 |

Open each file and run its contents in Developer Console Execute Anonymous, or use Salesforce CLI for the approved scratch org:

```bash
sf apex run --file scripts/apex/metadata-cleanup-audit/batch-01.apex --target-org crm-arbeidsforhold
```

Logs contain METADATA_AUDIT_BATCH_nn followed by indented JSON results. Record the approved target environment separately.
Export audit results without unrelated trace data using `npm run metadata:audit:export -- <debug-log-path>`.
Run only files listed in this index; older generated files may remain after the candidate list shrinks.

[Prerequisites and status meanings](../../../docs/operations/salesforce-metadata-cleanup-runbook.md#lesebasert-apex-kontroll).
