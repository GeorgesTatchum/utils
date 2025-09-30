INSERT INTO `oci_intervention` (
    `id`,
    `intervention_module_id`,
    `patient_id`,
    `owner_id`,
    `state`,
    `identifier`,
    `intervention_date`,
    `data`,
    `created_at`,
    `updated_at`
) VALUES (
    514,
    '–ø|\'Í,K·˜^Ü‚MÔ',
    '™M	Å	Å6þ²†?',
    10,
    'planning_closed',
    'EPK3D-225',
    '2025-09-16 00:00:00',
    '{
        "patientConsent": {
            "consentAI": true,
            "consentAILearning": true
        },
        "info": {
            "type": "TKA",
            "interventionSide": "Left",
            "allowGuide": true,
            "bonePhantom": false,
            "deliveryAddressComment": null,
            "comment": null,
            "deliveryAddress": 1,
            "radiologist": 9
        },
        "entryData": {
            "postal": false,
            "dicom": {
                "modality": "CT",
                "acquisitionDate": null,
                "uploadDate": "2025-09-15T13:12:40+02:00",
                "name": "68c7f4a8d5575.zip",
                "uploadedBy": 9
            },
            "radio": [],
            "other_file": []
        },
        "transitionLogs": {
            "finalise_draft": {
                "timestamp": "2025-09-15T13:09:51+02:00",
                "user": 8
            },
            "entrydata_upload": {
                "timestamp": "2025-09-15T13:12:41+02:00",
                "user": 9
            },
            "entrydata_accept": {
                "timestamp": "2025-09-15T13:19:57+02:00",
                "user": 4
            },
            "preplanning_upload": {
                "timestamp": "2025-09-15T13:22:20+02:00",
                "user": 4
            },
            "preplanning_close": {
                "timestamp": "2025-09-15T13:24:16+02:00",
                "user": 4
            },
            "planning_plan": {
                "timestamp": "2025-09-15T13:27:48+02:00",
                "user": 10
            },
            "planning_close": {
                "timestamp": "2025-09-15T13:29:43+02:00",
                "user": 10
            }
        },
        "mailInfo": {
            "sendMailToRadiologist": 9,
            "sendMailMethodIsPostal": false
        },
        "pre_planning": {
            "data": {
                "niftiRotationX": 2.7207,
                "niftiRotationY": 3.0264,
                "niftiRotationZ": -51.0851,
                "niftiTranslationX": 53.15,
                "niftiTranslationY": 70.6774,
                "niftiTranslationZ": 739.7941
            },
            "files": {
                "stlFilename": "68c7f6db4decd.zip",
                "niftiFilename": "68c7f6db53f7a.nii.gz"
            },
            "uploadDate": "2025-09-15T13:22:03+02:00",
            "uploadedBy": 4
        },
        "planner_data": {
            "preplanning": {
                "femur": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "notchingAnterior": 0,
                    "varusValgus": 0,
                    "varusValgusReference": "Valgus",
                    "distalResection": 8,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "femurRef": "posterior",
                    "femurRot": "mechanical_axis",
                    "femurMeasure": "condyle_posterior_line",
                    "femurProduct": "evolutis",
                    "femurRange": "uc",
                    "femurSize": 4,
                    "implant": {
                        "x": 1.5627236925526908,
                        "y": 0,
                        "z": 0
                    }
                },
                "tibia": {
                    "externalInternalRotation": -5,
                    "externalInternalRotationValueToDisplay": -5,
                    "externalInternalRotationReference": "Rotation interne",
                    "varusValgus": 0,
                    "varusValgusReference": "Varus",
                    "tibialResection": 9,
                    "tibialSlope": 0,
                    "tibiaRef": "akagi",
                    "tibiaMeasure": "akagi",
                    "tibiaProduct": "evolutis",
                    "tibiaRange": "mobile",
                    "tibiaSize": 4,
                    "insertSize": "4",
                    "implant": {
                        "x": 1.4922850891008697,
                        "y": 3.7036962875545187,
                        "z": 0
                    }
                },
                "patella": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "anteriorWidth": 10,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "patellaRef": "posterior",
                    "patellaProduct": "evolutis",
                    "patellaRange": "30",
                    "patellaSize": 10,
                    "implant": {
                        "x": 0,
                        "y": 0,
                        "z": 0
                    }
                }
            },
            "planning_measures": {
                "varus_valgus_reference": "Varus tibial",
                "varus_varus_angle": 2.5,
                "mldfa_angle": 85.2,
                "mpta_angle": 85.8,
                "internal_laxity": 0.5,
                "external_laxity": 2.9,
                "hks_angle": 2.7,
                "hks_sagittal_angle": 7,
                "flexion_extension_reference": "Flessum",
                "flexion_extension_angle": -2.5,
                "tibial_slope_angle": 5,
                "hka_initial_angle": 177.5,
                "hka_result_angle": 180,
                "tibia_length": 347.4,
                "femur_length": 419.1,
                "total_length": 766,
                "condyle_epicondyle_anatomical_angle": 0.4,
                "condyle_epicondyle_surgical_angle": 4.2,
                "condyle_whiteside_angle": 94,
                "akagi_posterior_angle": 17.2,
                "notching_anterior_measure": 10,
                "external_resection_tibial_measure": 9,
                "internal_resection_tibial_measure": 6,
                "external_resection_posterior_femoral_measure": 7.7,
                "internal_resection_posterior_femoral_measure": 7.8,
                "external_resection_distal_femoral_measure": 4.3,
                "internal_resection_distal_femoral_measure": 8,
                "patella_anterior_width_measure": -8,
                "patella_resection_posterior_measure": 8,
                "patella_to_femoral_cut_measure_0": 8,
                "patella_offset_measure": 5.1,
                "sum_implant_patella_to_femoral_cut_measure_0": 13.5,
                "patella_to_femoral_cut_measure_45": 11.9,
                "sum_implant_patella_to_femoral_cut_measure_45": 13.7,
                "patella_to_femoral_cut_measure_90": 8.3,
                "sum_implant_patella_to_femoral_cut_measure_90": 10
            },
            "planning": {
                "femur": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "notchingAnterior": 0,
                    "varusValgus": 0,
                    "varusValgusReference": "Valgus",
                    "distalResection": 8,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "femurRef": "posterior",
                    "femurRot": "mechanical_axis",
                    "femurMeasure": "condyle_posterior_line",
                    "femurProduct": "evolutis",
                    "femurRange": "uc",
                    "femurSize": 4,
                    "implant": {
                        "x": 1.5627236925526908,
                        "y": 0,
                        "z": 0
                    }
                },
                "tibia": {
                    "externalInternalRotation": -5,
                    "externalInternalRotationValueToDisplay": -5,
                    "externalInternalRotationReference": "Rotation interne",
                    "varusValgus": 0,
                    "varusValgusReference": "Varus",
                    "tibialResection": 9,
                    "tibialSlope": 0,
                    "tibiaRef": "akagi",
                    "tibiaMeasure": "akagi",
                    "tibiaProduct": "evolutis",
                    "tibiaRange": "mobile",
                    "tibiaSize": 4,
                    "insertSize": "4",
                    "implant": {
                        "x": 1.4922850891008697,
                        "y": 3.7036962875545187,
                        "z": 0
                    }
                },
                "patella": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "anteriorWidth": 10,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "patellaRef": "posterior",
                    "patellaProduct": "evolutis",
                    "patellaRange": "30",
                    "patellaSize": 10,
                    "implant": {
                        "x": 0,
                        "y": 0,
                        "z": 0
                    }
                }
            },
            "postplanning": {
                "femur": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "notchingAnterior": 0,
                    "varusValgus": 0,
                    "varusValgusReference": "Valgus",
                    "distalResection": 8,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "femurRef": "posterior",
                    "femurRot": "mechanical_axis",
                    "femurMeasure": "condyle_posterior_line",
                    "femurProduct": "evolutis",
                    "femurRange": "uc",
                    "femurSize": 4,
                    "implant": {
                        "x": 1.5627236925526908,
                        "y": 0,
                        "z": 0
                    }
                },
                "tibia": {
                    "externalInternalRotation": -5,
                    "externalInternalRotationValueToDisplay": -5,
                    "externalInternalRotationReference": "Rotation interne",
                    "varusValgus": 0,
                    "varusValgusReference": "Varus",
                    "tibialResection": 9,
                    "tibialSlope": 0,
                    "tibiaRef": "akagi",
                    "tibiaMeasure": "akagi",
                    "tibiaProduct": "evolutis",
                    "tibiaRange": "mobile",
                    "tibiaSize": 4,
                    "insertSize": "4",
                    "implant": {
                        "x": 1.4922850891008697,
                        "y": 3.7036962875545187,
                        "z": 0
                    }
                },
                "patella": {
                    "externalInternalRotation": 0,
                    "externalInternalRotationValueToDisplay": 0,
                    "externalInternalRotationReference": "Rotation externe",
                    "posteriorResection": 8,
                    "anteriorWidth": 10,
                    "flexionExtension": 0,
                    "flexionExtensionReference": "Flessum",
                    "patellaRef": "posterior",
                    "patellaProduct": "evolutis",
                    "patellaRange": "30",
                    "patellaSize": 10,
                    "implant": {
                        "x": 0,
                        "y": 0,
                        "z": 0
                    }
                }
            },
            "postplanning_measures": {
                "varus_valgus_reference": "Varus tibial",
                "varus_varus_angle": 2.5,
                "mldfa_angle": 85.2,
                "mpta_angle": 85.8,
                "internal_laxity": 0.5,
                "external_laxity": 2.9,
                "hks_angle": 2.7,
                "hks_sagittal_angle": 7,
                "flexion_extension_reference": "Flessum",
                "flexion_extension_angle": -2.5,
                "tibial_slope_angle": 5,
                "hka_initial_angle": 177.5,
                "hka_result_angle": 180,
                "tibia_length": 347.4,
                "femur_length": 419.1,
                "total_length": 766,
                "condyle_epicondyle_anatomical_angle": 0.4,
                "condyle_epicondyle_surgical_angle": 4.2,
                "condyle_whiteside_angle": 94,
                "akagi_posterior_angle": 17.2,
                "notching_anterior_measure": 10,
                "external_resection_tibial_measure": 9,
                "internal_resection_tibial_measure": 6,
                "external_resection_posterior_femoral_measure": 7.7,
                "internal_resection_posterior_femoral_measure": 7.8,
                "external_resection_distal_femoral_measure": 4.3,
                "internal_resection_distal_femoral_measure": 8,
                "patella_anterior_width_measure": -8,
                "patella_resection_posterior_measure": 8,
                "patella_to_femoral_cut_measure_0": 8,
                "patella_offset_measure": 5.1,
                "sum_implant_patella_to_femoral_cut_measure_0": 13.5,
                "patella_to_femoral_cut_measure_45": 11.9,
                "sum_implant_patella_to_femoral_cut_measure_45": 13.7,
                "patella_to_femoral_cut_measure_90": 8.3,
                "sum_implant_patella_to_femoral_cut_measure_90": 10
            }
        },
        "planner_screenshots": {
            "auto": [
                {"name": "screenshot", "name_report": "o", "filename": "68c7f832b68de.png"},
                {"name": "screenshot", "name_report": "f_1", "filename": "68c7f832bc198.png"},
                {"name": "screenshot", "name_report": "f_2", "filename": "68c7f832c2c2b.png"},
                {"name": "screenshot", "name_report": "f_3", "filename": "68c7f832c7d18.png"},
                {"name": "screenshot", "name_report": "t_1", "filename": "68c7f832cbf5c.png"},
                {"name": "screenshot", "name_report": "t_2", "filename": "68c7f832d02c4.png"},
                {"name": "screenshot", "name_report": "t_3", "filename": "68c7f832d46b1.png"},
                {"name": "screenshot", "name_report": "f_1_patella", "filename": "68c7f832d95bb.png"},
                {"name": "screenshot", "name_report": "f_2_patella", "filename": "68c7f832ddfc7.png"},
                {"name": "screenshot", "name_report": "f_3_patella", "filename": "68c7f832e2eed.png"},
                {"name": "screenshot", "name_report": "o_patella", "filename": "68c7f832eb426.png"},
                {"name": "screenshot", "name_report": "po_1", "filename": "68c7f832f280c.png"},
                {"name": "screenshot", "name_report": "po_2", "filename": "68c7f833052cb.png"}
            ]
        },
        "report_data": {
            "state": "done"
        }
    }',
    '2025-09-15 13:09:50',
    '2025-09-15 13:29:43'
);