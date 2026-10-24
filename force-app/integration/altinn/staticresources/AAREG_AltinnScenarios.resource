{
    "schemaVersion": 1,
    "scenarios": [
        {
            "name": "S01",
            "version": 1,
            "description": "Synthetic organization A permits application access. Observe the ordinary application and sharing flow.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization A",
                                "organizationNumber": "111111111",
                                "type": "Organization",
                                "unitType": "AS"
                            }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        }
                    ]
                }
            ]
        },
        {
            "name": "S02",
            "version": 1,
            "description": "Synthetic organization A denies application access and permits support. Expect support access only.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization A",
                                "organizationNumber": "111111111",
                                "type": "Organization",
                                "unitType": "AS"
                            }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        }
                    ]
                }
            ]
        },
        {
            "name": "S03",
            "version": 1,
            "description": "Synthetic organization A denies both resources. Use a clean user to observe no new shares; observe existing shares separately after Permit.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization A",
                                "organizationNumber": "111111111",
                                "type": "Organization",
                                "unitType": "AS"
                            }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        }
                    ]
                }
            ]
        },
        {
            "name": "S04",
            "version": 1,
            "description": "Synthetic organizations A and B have different rights. Switching organization must use the selected organization's matrix.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization A",
                                "organizationNumber": "111111111",
                                "type": "Organization",
                                "unitType": "AS"
                            },
                            {
                                "name": "Synthetic organization B",
                                "organizationNumber": "222222222",
                                "type": "Organization",
                                "unitType": "AS"
                            }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        },
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        },
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        }
                    ]
                }
            ]
        },
        {
            "name": "S05",
            "version": 1,
            "description": "A successful organization lookup returns an empty list. Observe the application's empty state without seeding any data.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": { "outcome": "Success", "organizations": [] },
                    "rights": []
                }
            ]
        },
        {
            "name": "S06",
            "version": 1,
            "description": "Return Organization entries with AS, ENK and BEDR forms plus a Person entry. Only the existing UI applies filtering.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization A",
                                "organizationNumber": "111111111",
                                "type": "Organization",
                                "unitType": "AS"
                            },
                            {
                                "name": "Synthetic organization B",
                                "organizationNumber": "222222222",
                                "type": "Organization",
                                "unitType": "ENK"
                            },
                            {
                                "name": "Synthetic organization C",
                                "organizationNumber": "333333333",
                                "type": "Organization",
                                "unitType": "BEDR"
                            },
                            { "name": "Synthetic person entry", "type": "Person" }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "333333333",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        },
                        {
                            "organizationNumber": "333333333",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        }
                    ]
                }
            ]
        },
        {
            "name": "S07",
            "version": 1,
            "description": "Robustness inputs distinguish response-level errors from thrown failures for both operations. This is not evidence of live Altinn failure semantics.",
            "classification": "Robustness",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "ResponseError",
                        "errorMessage": "Synthetic organization response error."
                    },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "ResponseError",
                            "errorMessage": "Synthetic rights response error."
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "ResponseError",
                            "errorMessage": "Synthetic rights response error."
                        }
                    ]
                },
                {
                    "alias": "subject-throws",
                    "organizations": { "outcome": "Exception", "errorMessage": "Synthetic organization exception." },
                    "rights": [
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Exception",
                            "errorMessage": "Synthetic rights exception."
                        },
                        {
                            "organizationNumber": "111111111",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Exception",
                            "errorMessage": "Synthetic rights exception."
                        }
                    ]
                }
            ]
        },
        {
            "name": "S08",
            "version": 1,
            "description": "Only synthetic organization B remains. Start with A previously selected through S01; observe stale-selection behavior without changing user records in the catalogue.",
            "classification": "ContractShape",
            "subjects": [
                {
                    "alias": "subject-a",
                    "organizations": {
                        "outcome": "Success",
                        "organizations": [
                            {
                                "name": "Synthetic organization B",
                                "organizationNumber": "222222222",
                                "type": "Organization",
                                "unitType": "AS"
                            }
                        ]
                    },
                    "rights": [
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-sok-tilgang",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Deny"
                        },
                        {
                            "organizationNumber": "222222222",
                            "resource": "nav_arbeidsforhold_aa-registeret-brukerstotte",
                            "outcome": "Decision",
                            "action": "Access",
                            "decision": "Permit"
                        }
                    ]
                }
            ]
        }
    ]
}
