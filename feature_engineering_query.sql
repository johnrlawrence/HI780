-- STEP 1: Create Cohort
-- Stratified sample: 5000 vented + 5000 never-vented ICD-10

CREATE OR REPLACE TEMP TABLE _SESSION.cohort_hadm_ids
AS
WITH
  vent AS (
    SELECT DISTINCT i.hadm_id
    FROM `physionet-data.mimiciv_3_1_derived.ventilation` v
    JOIN `physionet-data.mimiciv_3_1_icu.icustays` i
      ON v.stay_id = i.stay_id
    WHERE v.ventilation_status = 'InvasiveVent'
  ),
  icd10_admissions AS (
    SELECT DISTINCT a.hadm_id
    FROM `physionet-data.mimiciv_3_1_hosp.admissions` a
    JOIN `physionet-data.mimiciv_3_1_hosp.diagnoses_icd` d
      ON a.hadm_id = d.hadm_id
    WHERE d.icd_version = 10
  )
SELECT hadm_id
FROM
  (
    SELECT a.hadm_id
    FROM icd10_admissions a
    JOIN vent v
      ON a.hadm_id = v.hadm_id
    ORDER BY FARM_FINGERPRINT(CAST(a.hadm_id AS STRING))
    LIMIT 5000
  )
UNION ALL
SELECT hadm_id
FROM
  (
    SELECT a.hadm_id
    FROM icd10_admissions a
    LEFT JOIN vent v
      ON a.hadm_id = v.hadm_id
    WHERE v.hadm_id IS NULL
    ORDER BY FARM_FINGERPRINT(CAST(a.hadm_id AS STRING))
    LIMIT 5000
  );

-- STEP 1b: Careunit Mapping
-- Static lookup table mapping careunit strings to clinical category flags.
-- Created once and referenced by Steps 2 and 3.

CREATE OR REPLACE TEMP TABLE _SESSION.careunit_map_temp
AS
SELECT
  careunit,
  is_icu,
  is_ed,
  is_cardiology,
  is_intermediate,
  is_medicine,
  is_neuro,
  is_ob,
  is_observation,
  is_oncology,
  is_psych,
  is_stepdown,
  is_surgery,
  is_transplant,
  is_trauma,
  is_unknown_other,
  is_gyn
FROM
  UNNEST(
    [
      STRUCT(
        'Cardiac Surgery' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Cardiac Vascular Intensive Care Unit (CVICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Cardiology' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Cardiology Surgery Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        TRUE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Coronary Care Unit (CCU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Discharge Lounge' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Emergency Department' AS careunit,
        FALSE AS is_icu,
        TRUE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Emergency Department Observation' AS careunit,
        FALSE AS is_icu,
        TRUE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        TRUE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Hematology/Oncology' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        TRUE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Hematology/Oncology Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        TRUE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        TRUE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Intensive Care Unit (ICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Labor & Delivery' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        TRUE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Med/Surg' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        TRUE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Med/Surg/GYN' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        TRUE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        TRUE AS is_gyn),
      STRUCT(
        'Med/Surg/Trauma' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        TRUE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        TRUE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Medical Intensive Care Unit (MICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Medical/Surgical (Gynecology)' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        TRUE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        TRUE AS is_gyn),
      STRUCT(
        'Medical/Surgical Intensive Care Unit (MICU/SICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Medicine' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Medicine/Cardiology' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        FALSE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Medicine/Cardiology Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        TRUE AS is_cardiology,
        TRUE AS is_intermediate,
        TRUE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Neuro Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        TRUE AS is_intermediate,
        FALSE AS is_medicine,
        TRUE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Neuro Stepdown' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        TRUE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        TRUE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Neuro Surgical Intensive Care Unit (Neuro SICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        TRUE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Neurology' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        TRUE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Observation' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        TRUE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Obstetrics (Postpartum & Antepartum)' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        TRUE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Obstetrics Antepartum' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        TRUE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Obstetrics Postpartum' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        TRUE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Oncology' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        TRUE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Psychiatry' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        TRUE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgery' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgery/Pancreatic/Biliary/Bariatric' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgery/Trauma' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        TRUE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgery/Vascular/Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        TRUE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgical Intensive Care Unit (SICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Surgical Intermediate' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        TRUE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Thoracic Surgery' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Transplant' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        TRUE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Trauma SICU (TSICU)' AS careunit,
        TRUE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        TRUE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'UNKNOWN' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        TRUE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Unknown' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        TRUE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Vascular' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        TRUE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'PACU' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        FALSE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        TRUE AS is_unknown_other,
        FALSE AS is_gyn),
      STRUCT(
        'Nursery' AS careunit,
        FALSE AS is_icu,
        FALSE AS is_ed,
        FALSE AS is_cardiology,
        FALSE AS is_intermediate,
        FALSE AS is_medicine,
        FALSE AS is_neuro,
        TRUE AS is_ob,
        FALSE AS is_observation,
        FALSE AS is_oncology,
        FALSE AS is_psych,
        FALSE AS is_stepdown,
        FALSE AS is_surgery,
        FALSE AS is_transplant,
        FALSE AS is_trauma,
        FALSE AS is_unknown_other,
        FALSE AS is_gyn)]);

-- STEP 2: Create transfer unit flags
-- Maps each transfer segment to careunit category flags.
-- Used in block spine to identify ICU presence per block.

CREATE OR REPLACE TEMP TABLE _SESSION.transfers_units_temp
AS
WITH
  careunit_map AS (
    SELECT * FROM _SESSION.careunit_map_temp
  ),

  -- One row per transfer with careunit category flags
  transfers_units AS (
    SELECT
      t.hadm_id,
      t.intime,
      t.outtime,
      MAX(CASE WHEN cm.is_intermediate OR cm.is_stepdown THEN 1 ELSE 0 END)
        AS unit_intermediate_stepdown,
      MAX(CASE WHEN cm.is_cardiology THEN 1 ELSE 0 END) AS unit_cardiology,
      MAX(CASE WHEN cm.is_medicine THEN 1 ELSE 0 END) AS unit_medicine,
      MAX(CASE WHEN cm.is_surgery THEN 1 ELSE 0 END) AS unit_surgery,
      MAX(CASE WHEN cm.is_trauma THEN 1 ELSE 0 END) AS unit_trauma,
      MAX(CASE WHEN cm.is_neuro THEN 1 ELSE 0 END) AS unit_neuro,
      MAX(CASE WHEN cm.is_observation THEN 1 ELSE 0 END) AS unit_observation,
      MAX(CASE WHEN cm.is_icu THEN 1 ELSE 0 END) AS unit_icu
    FROM `physionet-data.mimiciv_3_1_hosp.transfers` t
    JOIN _SESSION.cohort_hadm_ids c
      ON t.hadm_id = c.hadm_id
    LEFT JOIN careunit_map cm
      ON t.careunit = cm.careunit
    WHERE
      t.hadm_id IS NOT NULL
      AND t.careunit IS NOT NULL
    GROUP BY t.hadm_id, t.intime, t.outtime
  )
SELECT * FROM transfers_units;

-- STEP 3: Eligible Admissions
-- Applies all cohort exclusions: ED, PACU, OB intubations,
-- ICU-start admissions, and DNI patients without intubation.

CREATE OR REPLACE TEMP TABLE _SESSION.admissions_temp
AS
WITH

  -- First invasive vent time per admission (cohort-scoped)
  vent_patients AS (
    SELECT i.hadm_id, MIN(v.starttime) AS vent_starttime
    FROM `physionet-data.mimiciv_3_1_derived.ventilation` v
    JOIN `physionet-data.mimiciv_3_1_icu.icustays` i
      ON v.stay_id = i.stay_id
    JOIN _SESSION.cohort_hadm_ids c
      ON i.hadm_id = c.hadm_id
    WHERE v.ventilation_status = 'InvasiveVent'
    GROUP BY i.hadm_id
  ),

  -- Careunit category mapping (repeated from Step 2 for self-contained logic)
  careunit_map AS (
    SELECT * FROM _SESSION.careunit_map_temp
  ),

  -- Transfer sequence used to identify first and second careunit
  transfers_ranked AS (
    SELECT
      t.hadm_id,
      t.careunit,
      t.intime,
      ROW_NUMBER()
        OVER (PARTITION BY t.hadm_id ORDER BY t.intime ASC) AS transfer_seq
    FROM `physionet-data.mimiciv_3_1_hosp.transfers` t
    JOIN _SESSION.cohort_hadm_ids c
      ON t.hadm_id = c.hadm_id
    WHERE t.hadm_id IS NOT NULL AND t.careunit IS NOT NULL
  ),

  -- First careunit per admission
  first_transfer AS (
    SELECT hadm_id, careunit AS first_careunit
    FROM transfers_ranked
    WHERE transfer_seq = 1
  ),

  -- Second careunit per admission (used for ED to ICU detection)
  second_transfer AS (
    SELECT hadm_id, careunit AS second_careunit
    FROM transfers_ranked
    WHERE transfer_seq = 2
  ),

  -- Flag admissions where first unit is ICU or ED to ICU
  started_on_icu AS (
    SELECT
      f.hadm_id,
      CASE
        WHEN cm1.is_icu THEN 1
        WHEN cm1.is_ed AND cm2.is_icu THEN 1
        ELSE 0
        END AS ed_or_direct_icu_flag
    FROM first_transfer f
    LEFT JOIN second_transfer s
      ON f.hadm_id = s.hadm_id
    LEFT JOIN careunit_map cm1
      ON f.first_careunit = cm1.careunit
    LEFT JOIN careunit_map cm2
      ON s.second_careunit = cm2.careunit
  ),

  -- First time each patient moved to a non-ICU unit (stepdown)
  first_stepdown AS (
    SELECT t.hadm_id, MIN(t.intime) AS first_non_icu_time
    FROM `physionet-data.mimiciv_3_1_hosp.transfers` t
    JOIN _SESSION.cohort_hadm_ids c
      ON t.hadm_id = c.hadm_id
    LEFT JOIN careunit_map cm
      ON t.careunit = cm.careunit
    WHERE
      (cm.is_icu = FALSE OR cm.is_icu IS NULL)
      AND t.careunit IS NOT NULL
    GROUP BY t.hadm_id
  ),

  -- Admissions excluded from cohort:
  --   Branch 1: intubation occurred in ED, PACU or OB unit
  --   Branch 2: started on ICU and intubated before first stepdown
  --   Branch 3: started on ICU and never stepped down
  excluded_admissions AS (
    SELECT DISTINCT t.hadm_id
    FROM `physionet-data.mimiciv_3_1_hosp.transfers` t
    JOIN `physionet-data.mimiciv_3_1_icu.icustays` i
      ON t.hadm_id = i.hadm_id
    JOIN `physionet-data.mimiciv_3_1_derived.ventilation` v
      ON i.stay_id = v.stay_id
    JOIN _SESSION.cohort_hadm_ids c
      ON t.hadm_id = c.hadm_id
    WHERE
      v.ventilation_status = 'InvasiveVent'
      AND v.starttime BETWEEN t.intime AND COALESCE(t.outtime, v.starttime)
      AND t.careunit IN (
        'Emergency Department', 'Emergency Department Observation', 'PACU',
        'Labor & Delivery', 'Obstetrics (Postpartum & Antepartum)',
        'Obstetrics Antepartum', 'Obstetrics Postpartum', 'Nursery')
    UNION DISTINCT
    SELECT s.hadm_id
    FROM started_on_icu s
    JOIN vent_patients vp
      ON s.hadm_id = vp.hadm_id
    JOIN first_stepdown fs
      ON s.hadm_id = fs.hadm_id
    WHERE
      s.ed_or_direct_icu_flag = 1
      AND vp.vent_starttime < fs.first_non_icu_time
    UNION DISTINCT
    SELECT s.hadm_id
    FROM started_on_icu s
    LEFT JOIN first_stepdown fs
      ON s.hadm_id = fs.hadm_id
    WHERE
      s.ed_or_direct_icu_flag = 1
      AND fs.first_non_icu_time IS NULL
  ),

  -- Never-vented patients with a DNI order at any point during admission
  dni_excluded_admissions AS (
    SELECT DISTINCT p.hadm_id
    FROM `physionet-data.mimiciv_3_1_hosp.poe` p
    JOIN _SESSION.cohort_hadm_ids c
      ON p.hadm_id = c.hadm_id
    JOIN `physionet-data.mimiciv_3_1_hosp.poe_detail` pd
      ON p.poe_id = pd.poe_id
    LEFT JOIN vent_patients vp
      ON p.hadm_id = vp.hadm_id
    WHERE
      p.order_type = 'General Care'
      AND p.order_subtype = 'Code status'
      AND pd.field_name = 'Code status'
      AND pd.field_value = 'Do not resuscitate (DNR/DNI)'
      AND vp.hadm_id IS NULL
  )

-- Final eligible admission list with admittime and dischtime
SELECT
  a.hadm_id,
  a.subject_id,
  a.admittime,
  a.dischtime
FROM `physionet-data.mimiciv_3_1_hosp.admissions` a
JOIN _SESSION.cohort_hadm_ids c
  ON a.hadm_id = c.hadm_id
LEFT JOIN excluded_admissions ex
  ON a.hadm_id = ex.hadm_id
LEFT JOIN dni_excluded_admissions dni
  ON a.hadm_id = dni.hadm_id
WHERE
  ex.hadm_id IS NULL
  AND dni.hadm_id IS NULL;

-- STEP 4: Ventilated Patients
-- First invasive vent starttime per eligible admission.
-- Used for block labeling and DNI-before-intubation filter.

CREATE OR REPLACE TEMP TABLE _SESSION.vent_patients_temp
AS
SELECT i.hadm_id, MIN(v.starttime) AS vent_starttime
FROM `physionet-data.mimiciv_3_1_derived.ventilation` v
JOIN `physionet-data.mimiciv_3_1_icu.icustays` i
  ON v.stay_id = i.stay_id
JOIN _SESSION.cohort_hadm_ids c
  ON i.hadm_id = c.hadm_id
WHERE v.ventilation_status = 'InvasiveVent'
GROUP BY i.hadm_id;

-- STEP 5: Final Feature Dataset
-- 12-hour block spine with 24-hour feature windows.
-- Label = 1 if intubation occurs in next 12 hours after block.
-- Excludes ICU blocks and blocks after intubation.

CREATE OR REPLACE TEMP TABLE _SESSION.final_dataset_temp
AS
WITH

  -- Age, age flag and gender per admission
  age_gender AS (
    SELECT
      a.hadm_id,
      LEAST(EXTRACT(YEAR FROM a.admittime) - p.anchor_year + p.anchor_age, 89)
        AS admit_age,
      CASE
        WHEN EXTRACT(YEAR FROM a.admittime) - p.anchor_year + p.anchor_age >= 89
          THEN 1
        ELSE 0
        END AS age_ge_89,
      p.gender
    FROM _SESSION.admissions_temp a
    JOIN `physionet-data.mimiciv_3_1_hosp.patients` p
      ON a.subject_id = p.subject_id
    WHERE (EXTRACT(YEAR FROM a.admittime) - p.anchor_year + p.anchor_age) >= 18
  ),

  -- Race mapped to OMB standard rollup categories
  race AS (
    SELECT
      a.hadm_id,
      adm.race AS race_raw,
      CASE adm.race
        WHEN 'AMERICAN INDIAN/ALASKA NATIVE'
          THEN 'American Indian / Alaska Native'
        WHEN 'ASIAN' THEN 'Asian'
        WHEN 'ASIAN - ASIAN INDIAN' THEN 'Asian'
        WHEN 'ASIAN - CHINESE' THEN 'Asian'
        WHEN 'ASIAN - KOREAN' THEN 'Asian'
        WHEN 'ASIAN - SOUTH EAST ASIAN' THEN 'Asian'
        WHEN 'BLACK/AFRICAN' THEN 'Black / African American'
        WHEN 'BLACK/AFRICAN AMERICAN' THEN 'Black / African American'
        WHEN 'BLACK/CAPE VERDEAN' THEN 'Black / African American'
        WHEN 'BLACK/CARIBBEAN ISLAND' THEN 'Black / African American'
        WHEN 'HISPANIC OR LATINO' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - CENTRAL AMERICAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - COLUMBIAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - CUBAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - DOMINICAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - GUATEMALAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - HONDURAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - MEXICAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - PUERTO RICAN' THEN 'Hispanic / Latino'
        WHEN 'HISPANIC/LATINO - SALVADORAN' THEN 'Hispanic / Latino'
        WHEN 'MULTIPLE RACE/ETHNICITY' THEN 'Multiple / Other'
        WHEN 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER'
          THEN 'Native Hawaiian / Pacific Islander'
        WHEN 'OTHER' THEN 'Multiple / Other'
        WHEN 'PATIENT DECLINED TO ANSWER' THEN 'Unknown / Not Reported'
        WHEN 'PORTUGUESE' THEN 'White'
        WHEN 'SOUTH AMERICAN' THEN 'Hispanic / Latino'
        WHEN 'UNABLE TO OBTAIN' THEN 'Unknown / Not Reported'
        WHEN 'UNKNOWN' THEN 'Unknown / Not Reported'
        WHEN 'WHITE' THEN 'White'
        WHEN 'WHITE - BRAZILIAN' THEN 'White'
        WHEN 'WHITE - EASTERN EUROPEAN' THEN 'White'
        WHEN 'WHITE - OTHER EUROPEAN' THEN 'White'
        WHEN 'WHITE - RUSSIAN' THEN 'White'
        ELSE 'Unknown / Not Reported'
        END AS race_rollup
    FROM _SESSION.admissions_temp a
    JOIN `physionet-data.mimiciv_3_1_hosp.admissions` adm
      ON a.hadm_id = adm.hadm_id
  ),

  -- Pre-admission baseline vitals from OMR (365-day lookback)
  omr_vitals AS (
    SELECT
      a.hadm_id,
      MAX(
        CASE
          WHEN o.result_name = 'BMI (kg/m2)'
            THEN SAFE_CAST(o.result_value AS FLOAT64)
          END) AS bmi_max,
      MAX(
        CASE
          WHEN o.result_name = 'Blood Pressure'
            THEN
              SAFE_CAST(SPLIT(o.result_value, '/')[SAFE_OFFSET(0)] AS FLOAT64)
          END) AS sbp_max,
      MIN(
        CASE
          WHEN o.result_name = 'Blood Pressure'
            THEN
              SAFE_CAST(SPLIT(o.result_value, '/')[SAFE_OFFSET(0)] AS FLOAT64)
          END) AS sbp_min,
      MAX(
        CASE
          WHEN o.result_name = 'Blood Pressure'
            THEN
              SAFE_CAST(SPLIT(o.result_value, '/')[SAFE_OFFSET(1)] AS FLOAT64)
          END) AS dbp_max,
      MIN(
        CASE
          WHEN o.result_name = 'Blood Pressure'
            THEN
              SAFE_CAST(SPLIT(o.result_value, '/')[SAFE_OFFSET(1)] AS FLOAT64)
          END) AS dbp_min
    FROM _SESSION.admissions_temp a
    JOIN `physionet-data.mimiciv_3_1_hosp.omr` o
      ON
        o.subject_id = a.subject_id
        AND o.chartdate >= DATE_SUB(DATE(a.admittime), INTERVAL 365 DAY)
        AND o.chartdate < DATE(a.admittime)
    WHERE o.result_name IN ('BMI (kg/m2)', 'Blood Pressure')
    GROUP BY a.hadm_id
  ),

  -- Medication administration flags per hadm_id and charttime
  -- Timing anchor: emar.charttime (time of documented administration)
  emar_meds AS (
    SELECT
      e.hadm_id,
      e.charttime,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'vancomycin|piperacillin|cefepime|ceftriaxone|cefazolin|meropenem|metronidazole|ampicillin|ciprofloxacin|azithromycin|doxycycline|clindamycin|sulfameth|ceftazidime|amoxicillin|cephalexin|levofloxacin|daptomycin|aztreonam|imipenem')
            AND COALESCE(ph.route, '')
              NOT IN (
                'BOTH EYES', 'LEFT EYE', 'RIGHT EYE', 'LEFT EAR', 'RIGHT EAR',
                'BOTH EARS', 'AU', 'AS', 'OD', 'IT')
            THEN 1
          ELSE 0
          END) AS antibiotic,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'fluconazole|micafungin|caspofungin|voriconazole|amphotericin|anidulafungin|itraconazole|posaconazole')
            THEN 1
          ELSE 0
          END) AS antifungal,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'fentanyl|hydromorphone|dilaudid|morphine|oxycodone|methadone|tramadol|opium|buprenorphine|meperidine|codeine|hydrocodone')
            AND COALESCE(ed.administration_type, '') != 'Epidural'
            THEN 1
          ELSE 0
          END) AS opioid,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'propofol|midazolam|lorazepam|diazepam|dexmedetomidine|ketamine|clonazepam|alprazolam|phenobarbital|chlordiazepoxide')
            THEN 1
          ELSE 0
          END) AS sedative,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'furosemide|torsemide|bumetanide|spironolactone|hydrochlorothiazide|metolazone|chlorthalidone')
            THEN 1
          ELSE 0
          END) AS diuretic,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'albuterol|ipratropium|tiotropium|levalbuterol|salmeterol|formoterol|racepinephrine')
            THEN 1
          ELSE 0
          END) AS bronchodilator,
      MAX(
        CASE
          WHEN
            REGEXP_CONTAINS(
              LOWER(e.medication),
              r'prednisone|methylprednisolone|dexamethasone|hydrocortisone|prednisolone|budesonide|fludrocortisone')
            AND COALESCE(ph.route, '')
              IN (
                'PO/NG', 'IV', 'PO', 'NG', 'IM', 'IV DRIP', 'SC', 'INHALATION',
                'IH', 'INTRATRACHEAL')
            THEN 1
          ELSE 0
          END) AS steroid
    FROM `physionet-data.mimiciv_3_1_hosp.emar` e
    JOIN _SESSION.admissions_temp a
      ON e.hadm_id = a.hadm_id
    LEFT JOIN `physionet-data.mimiciv_3_1_hosp.emar_detail` ed
      ON
        e.emar_id = ed.emar_id
        AND ed.parent_field_ordinal = '1.1'
    LEFT JOIN `physionet-data.mimiciv_3_1_hosp.pharmacy` ph
      ON e.pharmacy_id = ph.pharmacy_id
    WHERE
      e.event_txt IN (
        'Administered', 'Delayed Administered',
        'Administered Bolus from IV Drip', 'Administered in Other Location',
        'Applied', 'Applied in Other Location',
        'Removed Existing / Applied New', 'Started', 'Delayed Started',
        'Started in Other Location')
    GROUP BY e.hadm_id, e.charttime
  ),

  -- Physician order flags per hadm_id and ordertime
  -- Excludes admissions where DNI order preceded intubation
  -- Timing anchor: poe.ordertime (when order was placed)
  poe_orders AS (
    SELECT
      p.hadm_id,
      p.ordertime,
      MAX(
        CASE
          WHEN
            p.order_type = 'Respiratory'
            AND p.order_subtype = 'Oxygen Therapy'
            THEN 1
          ELSE 0
          END) AS resp_oxygen_therapy,
      MAX(
        CASE
          WHEN p.order_type = 'Respiratory' AND p.order_subtype = 'BiPAP' THEN 1
          ELSE 0
          END) AS resp_bipap,
      MAX(
        CASE
          WHEN p.order_type = 'Respiratory' AND p.order_subtype = 'CPAP for OSA'
            THEN 1
          ELSE 0
          END) AS resp_cpap,
      MAX(
        CASE
          WHEN
            p.order_type = 'Respiratory'
            AND p.order_subtype = 'Respiratory Therapy Consult'
            THEN 1
          ELSE 0
          END) AS resp_therapy_consult,
      MAX(
        CASE
          WHEN
            p.order_type = 'Radiology'
            AND p.order_subtype IN ('General Xray', 'CT Scan')
            THEN 1
          ELSE 0
          END) AS radiology_chest_imaging,
      MAX(
        CASE
          WHEN
            p.order_type = 'General Care'
            AND p.order_subtype = 'Code status'
            AND pd.field_name = 'Code status'
            AND pd.field_value
              = 'DNAR (DO NOT attempt resuscitation for cardiac arrest)'
            THEN 1
          ELSE 0
          END) AS code_dnr,
      MAX(
        CASE
          WHEN
            p.order_type = 'Consults'
            AND p.order_subtype = 'Speech/Swallowing'
            THEN 1
          ELSE 0
          END) AS consult_speech_swallow,
      MAX(
        CASE
          WHEN p.order_type = 'Consults' AND p.order_subtype = 'Pulmonary'
            THEN 1
          ELSE 0
          END) AS consult_pulmonary,
      MAX(
        CASE
          WHEN
            p.order_type = 'Consults'
            AND p.order_subtype = 'Interventional Pulmonology'
            THEN 1
          ELSE 0
          END) AS consult_interventional_pulm,
      MAX(
        CASE
          WHEN
            p.order_type = 'Consults'
            AND p.order_subtype = 'Infectious Disease'
            THEN 1
          ELSE 0
          END) AS consult_infectious_disease,
      MAX(
        CASE
          WHEN p.order_type = 'Consults' AND p.order_subtype = 'Nephrology'
            THEN 1
          ELSE 0
          END) AS consult_nephrology,
      MAX(
        CASE
          WHEN
            p.order_type = 'Consults'
            AND p.order_subtype IN (
              'Palliative Care', 'Palliative Care/Ethics Support')
            THEN 1
          ELSE 0
          END) AS consult_palliative,
      MAX(
        CASE
          WHEN p.order_type = 'Consults' AND p.order_subtype = 'Neurology'
            THEN 1
          ELSE 0
          END) AS consult_neurology,
      MAX(
        CASE
          WHEN p.order_type = 'Consults' AND p.order_subtype = 'Neurosurgery'
            THEN 1
          ELSE 0
          END) AS consult_neurosurgery,
      MAX(
        CASE
          WHEN
            p.order_type = 'Hemodialysis'
            AND p.order_subtype = 'Hemodialysis'
            THEN 1
          ELSE 0
          END) AS hemodialysis,
      MAX(
        CASE
          WHEN
            p.order_type = 'Nutrition'
            AND p.order_subtype = 'Tubefeeding Order'
            THEN 1
          ELSE 0
          END) AS nutrition_tubefeeding,
      MAX(
        CASE
          WHEN
            p.order_type = 'Nutrition'
            AND p.order_subtype = 'NPO/Diet for Procedure'
            THEN 1
          ELSE 0
          END) AS nutrition_npo,
      MAX(
        CASE
          WHEN p.order_type = 'Neurology' AND p.order_subtype = 'EEG' THEN 1
          ELSE 0
          END) AS neuro_eeg,
      MAX(
        CASE
          WHEN
            p.order_type = 'General Care'
            AND p.order_subtype IN (
              'Telemetry', 'Telemetry: Cardiac, cont SpO2')
            THEN 1
          ELSE 0
          END) AS general_telemetry,
      MAX(
        CASE
          WHEN
            p.order_type = 'General Care'
            AND p.order_subtype = 'Tubes/Drains'
            AND pd.field_name = 'Tubes & Drains type'
            AND pd.field_value IN ('NGT', 'OGT', 'Post-pyloric tube')
            THEN 1
          ELSE 0
          END) AS tube_ngt_ogt,
      MAX(
        CASE
          WHEN
            p.order_type = 'General Care'
            AND p.order_subtype = 'Tubes/Drains'
            AND pd.field_name = 'Tubes & Drains type'
            AND pd.field_value = 'Chest tube'
            THEN 1
          ELSE 0
          END) AS tube_chest
    FROM `physionet-data.mimiciv_3_1_hosp.poe` p
    JOIN _SESSION.admissions_temp a
      ON p.hadm_id = a.hadm_id
    LEFT JOIN `physionet-data.mimiciv_3_1_hosp.poe_detail` pd
      ON p.poe_id = pd.poe_id
    LEFT JOIN
      (
        -- Admissions where DNI order preceded intubation (excluded from poe features)
        SELECT DISTINCT p2.hadm_id
        FROM `physionet-data.mimiciv_3_1_hosp.poe` p2
        JOIN `physionet-data.mimiciv_3_1_hosp.poe_detail` pd2
          ON p2.poe_id = pd2.poe_id
        JOIN _SESSION.vent_patients_temp vp
          ON p2.hadm_id = vp.hadm_id
        WHERE
          p2.order_type = 'General Care'
          AND p2.order_subtype = 'Code status'
          AND pd2.field_name = 'Code status'
          AND pd2.field_value = 'Do not resuscitate (DNR/DNI)'
          AND p2.ordertime < vp.vent_starttime
      ) dni_poe
      ON p.hadm_id = dni_poe.hadm_id
    WHERE dni_poe.hadm_id IS NULL
    GROUP BY p.hadm_id, p.ordertime
  ),

  -- 12-hour block grid per admission from admittime to dischtime
  -- Feature window: 24-hour lookback from block_end
  -- Label window: 12-hour lookahead from block_end
  block_spine AS (
    SELECT
      a.hadm_id,
      a.admittime,
      a.dischtime,
      block_num,
      TIMESTAMP_ADD(a.admittime, INTERVAL (block_num * 12) HOUR) AS block_start,
      TIMESTAMP_ADD(a.admittime, INTERVAL ((block_num + 1) * 12) HOUR)
        AS block_end,
      TIMESTAMP_ADD(a.admittime, INTERVAL ((block_num + 1) * 12) HOUR)
        - INTERVAL 24 HOUR AS feature_window_start,
      TIMESTAMP_ADD(a.admittime, INTERVAL ((block_num + 1) * 12) HOUR)
        AS feature_window_end
    FROM _SESSION.admissions_temp a
    CROSS JOIN
      UNNEST(
        GENERATE_ARRAY(
          0,
          CAST(
            CEIL(TIMESTAMP_DIFF(a.dischtime, a.admittime, HOUR) / 12)
            - 1
            AS INT64))) AS block_num
    WHERE TIMESTAMP_DIFF(a.dischtime, a.admittime, HOUR) >= 12
  ),

  -- Attaches vent label, already-vented flag and ICU presence to each block
  block_labeled AS (
    SELECT
      bs.hadm_id,
      bs.block_num,
      bs.block_start,
      bs.block_end,
      bs.feature_window_start,
      bs.feature_window_end,
      CASE
        WHEN
          vp.vent_starttime >= bs.block_end
          AND vp.vent_starttime < TIMESTAMP_ADD(bs.block_end, INTERVAL 12 HOUR)
          THEN 1
        ELSE 0
        END AS label_vent_next_12h,
      CASE
        WHEN vp.vent_starttime < bs.block_end THEN 1
        ELSE 0
        END AS already_vented,
      MAX(CASE WHEN tu.unit_icu = 1 THEN 1 ELSE 0 END) AS block_has_icu
    FROM block_spine bs
    LEFT JOIN _SESSION.vent_patients_temp vp
      ON bs.hadm_id = vp.hadm_id
    LEFT JOIN _SESSION.transfers_units_temp tu
      ON
        tu.hadm_id = bs.hadm_id
        AND tu.intime < bs.block_end
        AND COALESCE(tu.outtime, bs.block_end) > bs.block_start
    GROUP BY
      bs.hadm_id, bs.block_num, bs.block_start, bs.block_end,
      bs.feature_window_start, bs.feature_window_end, vp.vent_starttime
  ),

  -- Retains only non-ICU blocks that precede intubation
  block_final AS (
    SELECT
      hadm_id,
      block_num,
      block_start,
      block_end,
      feature_window_start,
      feature_window_end,
      label_vent_next_12h
    FROM block_labeled
    WHERE
      already_vented = 0
      AND block_has_icu = 0
  ),

  -- Lab abnormality flags and mean values per block (24h window)
  -- Abnormal flag: flag='abnormal' OR valuenum outside ref range
  -- Timing anchor: labevents.storetime (when result was verified)
  block_labs AS (
    SELECT
      bf.hadm_id,
      bf.block_num,
      MAX(
        CASE
          WHEN
            le.itemid IN (50912, 52024)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS cr_high,
      AVG(CASE WHEN le.itemid IN (50912, 52024) THEN le.valuenum END)
        AS cr_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (50931, 50809)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS gluc_high,
      MAX(
        CASE
          WHEN
            le.itemid IN (50931, 50809)
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS gluc_low,
      AVG(CASE WHEN le.itemid IN (50931, 50809) THEN le.valuenum END)
        AS gluc_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (51222, 50811)
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS hgb_low,
      AVG(CASE WHEN le.itemid IN (51222, 50811) THEN le.valuenum END)
        AS hgb_mean,
      MAX(
        CASE
          WHEN
            le.itemid = 50963
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS bnp_high,
      AVG(CASE WHEN le.itemid = 50963 THEN le.valuenum END) AS bnp_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (50818, 52040)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS pco2_high,
      AVG(CASE WHEN le.itemid IN (50818, 52040) THEN le.valuenum END)
        AS pco2_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (50820, 50831)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS ph_high,
      MAX(
        CASE
          WHEN
            le.itemid IN (50820, 50831)
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS ph_low,
      AVG(CASE WHEN le.itemid IN (50820, 50831) THEN le.valuenum END)
        AS ph_mean,
      MAX(
        CASE
          WHEN
            le.itemid = 50821
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS po2_low,
      AVG(CASE WHEN le.itemid = 50821 THEN le.valuenum END) AS po2_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (50971, 50822)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS k_high,
      MAX(
        CASE
          WHEN
            le.itemid IN (50971, 50822)
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS k_low,
      AVG(CASE WHEN le.itemid IN (50971, 50822) THEN le.valuenum END) AS k_mean,
      MAX(
        CASE
          WHEN
            le.itemid IN (50983, 50824)
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS na_high,
      MAX(
        CASE
          WHEN
            le.itemid IN (50983, 50824)
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS na_low,
      AVG(CASE WHEN le.itemid IN (50983, 50824) THEN le.valuenum END)
        AS na_mean,
      MAX(
        CASE
          WHEN
            le.itemid = 51003
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS tnt_high,
      AVG(CASE WHEN le.itemid = 51003 THEN le.valuenum END) AS tnt_mean,
      MAX(
        CASE
          WHEN
            le.itemid = 51301
            AND (le.flag = 'abnormal' OR le.valuenum > le.ref_range_upper)
            THEN 1
          ELSE 0
          END) AS wbc_high,
      MAX(
        CASE
          WHEN
            le.itemid = 51301
            AND (le.flag = 'abnormal' OR le.valuenum < le.ref_range_lower)
            THEN 1
          ELSE 0
          END) AS wbc_low,
      AVG(CASE WHEN le.itemid = 51301 THEN le.valuenum END) AS wbc_mean
    FROM block_final bf
    JOIN `physionet-data.mimiciv_3_1_hosp.labevents` le
      ON
        le.hadm_id = bf.hadm_id
        AND le.storetime >= bf.feature_window_start
        AND le.storetime < bf.feature_window_end
        AND le.valuenum IS NOT NULL
    WHERE
      le.itemid IN (
        50912, 52024,  -- Creatinine
        50931, 50809,  -- Glucose
        51222, 50811,  -- Hemoglobin
        50963,  -- NTproBNP
        50818, 52040,  -- pCO2
        50820, 50831,  -- pH
        50821,  -- pO2
        50971, 50822,  -- Potassium
        50983, 50824,  -- Sodium
        51003,  -- Troponin T
        51301  -- WBC
      )
    GROUP BY bf.hadm_id, bf.block_num
  ),

  -- Medication class flags aggregated to block level (24h window)
  block_meds AS (
    SELECT
      bf.hadm_id,
      bf.block_num,
      MAX(em.antibiotic) AS antibiotic,
      MAX(em.antifungal) AS antifungal,
      MAX(em.opioid) AS opioid,
      MAX(em.sedative) AS sedative,
      MAX(em.diuretic) AS diuretic,
      MAX(em.bronchodilator) AS bronchodilator,
      MAX(em.steroid) AS steroid
    FROM block_final bf
    JOIN emar_meds em
      ON
        em.hadm_id = bf.hadm_id
        AND em.charttime >= bf.feature_window_start
        AND em.charttime < bf.feature_window_end
    GROUP BY bf.hadm_id, bf.block_num
  ),

  -- Physician order flags aggregated to block level (24h window)
  block_orders AS (
    SELECT
      bf.hadm_id,
      bf.block_num,
      MAX(po.resp_oxygen_therapy) AS resp_oxygen_therapy,
      MAX(po.resp_bipap) AS resp_bipap,
      MAX(po.resp_cpap) AS resp_cpap,
      MAX(po.resp_therapy_consult) AS resp_therapy_consult,
      MAX(po.radiology_chest_imaging) AS radiology_chest_imaging,
      MAX(po.code_dnr) AS code_dnr,
      MAX(po.consult_speech_swallow) AS consult_speech_swallow,
      MAX(po.consult_pulmonary) AS consult_pulmonary,
      MAX(po.consult_interventional_pulm) AS consult_interventional_pulm,
      MAX(po.consult_infectious_disease) AS consult_infectious_disease,
      MAX(po.consult_nephrology) AS consult_nephrology,
      MAX(po.consult_palliative) AS consult_palliative,
      MAX(po.consult_neurology) AS consult_neurology,
      MAX(po.consult_neurosurgery) AS consult_neurosurgery,
      MAX(po.hemodialysis) AS hemodialysis,
      MAX(po.nutrition_tubefeeding) AS nutrition_tubefeeding,
      MAX(po.nutrition_npo) AS nutrition_npo,
      MAX(po.neuro_eeg) AS neuro_eeg,
      MAX(po.general_telemetry) AS general_telemetry,
      MAX(po.tube_ngt_ogt) AS tube_ngt_ogt,
      MAX(po.tube_chest) AS tube_chest
    FROM block_final bf
    JOIN poe_orders po
      ON
        po.hadm_id = bf.hadm_id
        AND po.ordertime >= bf.feature_window_start
        AND po.ordertime < bf.feature_window_end
    GROUP BY bf.hadm_id, bf.block_num
  ),

  -- Microbiology flags per block
  -- Gram stain: 24h feature window (1-2h turnaround)
  -- Culture positivity: 72h carry-forward (24-72h turnaround)
  -- Timing anchor: microbiologyevents.storetime
  block_micro AS (
    SELECT
      bf.hadm_id,
      bf.block_num,
      MAX(
        CASE
          WHEN
            m.storetime >= bf.feature_window_start
            AND m.storetime < bf.feature_window_end
            AND REGEXP_CONTAINS(
              LOWER(m.test_name),
              r'gram stain|aerobic bottle gram|anaerobic bottle gram')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS gram_stain_positive,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'BLOOD CULTURE', 'BLOOD CULTURE ( MYCO/F LYTIC BOTTLE)',
              'FLUID RECEIVED IN BLOOD CULTURE BOTTLES',
              'Stem Cell - Blood Culture', 'BLOOD CULTURE - NEONATE', 'BLOOD')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_blood,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'SPUTUM',
              'BRONCHOALVEOLAR LAVAGE',
              'BRONCHIAL WASHINGS',
              'Mini-BAL',
              'BRONCHIAL BRUSH',
              'BRONCHIAL BRUSH - PROTECTED',
              'TRACHEAL ASPIRATE',
              'Influenza A/B by DFA',
              'Influenza A/B by DFA - Bronch Lavage',
              'Rapid Respiratory Viral Screen & Culture',
              'RAPID RESPIRATORY VIRAL ANTIGEN TEST')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_respiratory,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'URINE', 'URINE,KIDNEY', 'URINE,SUPRAPUBIC ASPIRATE')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_urine,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc = 'CSF;SPINAL FLUID'
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_csf,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'SWAB', 'Swab', 'ABSCESS', 'FLUID WOUND', 'FOOT CULTURE',
              'FOREIGN BODY', 'Foreign Body - Sonication Culture', 'EAR', 'EYE',
              'CORNEAL EYE SCRAPINGS')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_wound,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'TISSUE', 'BIOPSY', 'BONE MARROW', 'ASPIRATE',
              'Touch Prep/Sections')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_tissue,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'PERITONEAL FLUID', 'PLEURAL FLUID', 'FLUID,OTHER', 'JOINT FLUID',
              'BILE', 'DIALYSIS FLUID', 'PROSTHETIC JOINT FLUID',
              'AMNIOTIC FLUID')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_fluid,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc IN (
              'THROAT FOR STREP', 'THROAT CULTURE', 'THROAT')
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_throat,
      MAX(
        CASE
          WHEN
            m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
            AND m.storetime < bf.block_end
            AND m.spec_type_desc = 'CATHETER TIP-IV'
            AND m.org_name IS NOT NULL
            AND m.org_name != 'CANCELLED'
            THEN 1
          ELSE 0
          END) AS culture_positive_device
    FROM block_final bf
    JOIN `physionet-data.mimiciv_3_1_hosp.microbiologyevents` m
      ON
        m.hadm_id = bf.hadm_id
        AND m.storetime < bf.block_end
        AND m.storetime >= TIMESTAMP_SUB(bf.block_end, INTERVAL 72 HOUR)
    GROUP BY bf.hadm_id, bf.block_num
  ),

  -- Careunit category flags for any transfer segment overlapping the block
  block_transfers AS (
    SELECT
      bf.hadm_id,
      bf.block_num,
      MAX(tu.unit_intermediate_stepdown) AS unit_intermediate_stepdown,
      MAX(tu.unit_cardiology) AS unit_cardiology,
      MAX(tu.unit_medicine) AS unit_medicine,
      MAX(tu.unit_surgery) AS unit_surgery,
      MAX(tu.unit_trauma) AS unit_trauma,
      MAX(tu.unit_neuro) AS unit_neuro,
      MAX(tu.unit_observation) AS unit_observation
    FROM block_final bf
    JOIN _SESSION.transfers_units_temp tu
      ON
        tu.hadm_id = bf.hadm_id
        AND tu.intime < bf.block_end
        AND COALESCE(tu.outtime, bf.block_end) > bf.block_start
    GROUP BY bf.hadm_id, bf.block_num
  ),

  -- Final assembled feature set with de-identified patient and admission IDs
  final_dataset AS (
    SELECT
      -- De-identified identifiers (patient_id preserved across admissions)
      DENSE_RANK() OVER (ORDER BY a.subject_id) AS patient_id,
      DENSE_RANK() OVER (ORDER BY bf.hadm_id) AS admission_id,
      bf.block_num,

      -- Outcome label
      bf.label_vent_next_12h,

      -- Static: demographics
      ag.admit_age,
      ag.age_ge_89,
      ag.gender,
      r.race_rollup,

      -- Static: pre-admission baseline vitals (365-day OMR lookback)
      ov.bmi_max,
      ov.sbp_max,
      ov.sbp_min,
      ov.dbp_max,
      ov.dbp_min,

      -- Labs (24h window)
      bl.cr_high,
      bl.cr_mean,
      bl.gluc_high,
      bl.gluc_low,
      bl.gluc_mean,
      bl.hgb_low,
      bl.hgb_mean,
      bl.bnp_high,
      bl.bnp_mean,
      bl.pco2_high,
      bl.pco2_mean,
      bl.ph_high,
      bl.ph_low,
      bl.ph_mean,
      bl.po2_low,
      bl.po2_mean,
      bl.k_high,
      bl.k_low,
      bl.k_mean,
      bl.na_high,
      bl.na_low,
      bl.na_mean,
      bl.tnt_high,
      bl.tnt_mean,
      bl.wbc_high,
      bl.wbc_low,
      bl.wbc_mean,

      -- Medications (24h window; 0 if no administration in window)
      COALESCE(bm.antibiotic, 0) AS antibiotic,
      COALESCE(bm.antifungal, 0) AS antifungal,
      COALESCE(bm.opioid, 0) AS opioid,
      COALESCE(bm.sedative, 0) AS sedative,
      COALESCE(bm.diuretic, 0) AS diuretic,
      COALESCE(bm.bronchodilator, 0) AS bronchodilator,
      COALESCE(bm.steroid, 0) AS steroid,

      -- Physician orders (24h window; 0 if no order in window)
      COALESCE(bo.resp_oxygen_therapy, 0) AS resp_oxygen_therapy,
      COALESCE(bo.resp_bipap, 0) AS resp_bipap,
      COALESCE(bo.resp_cpap, 0) AS resp_cpap,
      COALESCE(bo.resp_therapy_consult, 0) AS resp_therapy_consult,
      COALESCE(bo.radiology_chest_imaging, 0) AS radiology_chest_imaging,
      COALESCE(bo.code_dnr, 0) AS code_dnr,
      COALESCE(bo.consult_speech_swallow, 0) AS consult_speech_swallow,
      COALESCE(bo.consult_pulmonary, 0) AS consult_pulmonary,
      COALESCE(bo.consult_interventional_pulm, 0)
        AS consult_interventional_pulm,
      COALESCE(bo.consult_infectious_disease, 0) AS consult_infectious_disease,
      COALESCE(bo.consult_nephrology, 0) AS consult_nephrology,
      COALESCE(bo.consult_palliative, 0) AS consult_palliative,
      COALESCE(bo.consult_neurology, 0) AS consult_neurology,
      COALESCE(bo.consult_neurosurgery, 0) AS consult_neurosurgery,
      COALESCE(bo.hemodialysis, 0) AS hemodialysis,
      COALESCE(bo.nutrition_tubefeeding, 0) AS nutrition_tubefeeding,
      COALESCE(bo.nutrition_npo, 0) AS nutrition_npo,
      COALESCE(bo.neuro_eeg, 0) AS neuro_eeg,
      COALESCE(bo.general_telemetry, 0) AS general_telemetry,
      COALESCE(bo.tube_ngt_ogt, 0) AS tube_ngt_ogt,
      COALESCE(bo.tube_chest, 0) AS tube_chest,

      -- Microbiology (gram stain: 24h; cultures: 72h carry-forward; 0 if absent)
      COALESCE(bmi.gram_stain_positive, 0) AS gram_stain_positive,
      COALESCE(bmi.culture_positive_blood, 0) AS culture_positive_blood,
      COALESCE(bmi.culture_positive_respiratory, 0)
        AS culture_positive_respiratory,
      COALESCE(bmi.culture_positive_urine, 0) AS culture_positive_urine,
      COALESCE(bmi.culture_positive_csf, 0) AS culture_positive_csf,
      COALESCE(bmi.culture_positive_wound, 0) AS culture_positive_wound,
      COALESCE(bmi.culture_positive_tissue, 0) AS culture_positive_tissue,
      COALESCE(bmi.culture_positive_fluid, 0) AS culture_positive_fluid,
      COALESCE(bmi.culture_positive_throat, 0) AS culture_positive_throat,
      COALESCE(bmi.culture_positive_device, 0) AS culture_positive_device,

      -- Careunit flags (block presence; 0 if not present during block)
      COALESCE(bt.unit_intermediate_stepdown, 0) AS unit_intermediate_stepdown,
      COALESCE(bt.unit_cardiology, 0) AS unit_cardiology,
      COALESCE(bt.unit_medicine, 0) AS unit_medicine,
      COALESCE(bt.unit_surgery, 0) AS unit_surgery,
      COALESCE(bt.unit_trauma, 0) AS unit_trauma,
      COALESCE(bt.unit_neuro, 0) AS unit_neuro,
      COALESCE(bt.unit_observation, 0) AS unit_observation
    FROM block_final bf
    JOIN _SESSION.admissions_temp a
      ON bf.hadm_id = a.hadm_id
    LEFT JOIN age_gender ag
      ON bf.hadm_id = ag.hadm_id
    LEFT JOIN race r
      ON bf.hadm_id = r.hadm_id
    LEFT JOIN omr_vitals ov
      ON bf.hadm_id = ov.hadm_id
    LEFT JOIN block_labs bl
      ON bf.hadm_id = bl.hadm_id AND bf.block_num = bl.block_num
    LEFT JOIN block_meds bm
      ON bf.hadm_id = bm.hadm_id AND bf.block_num = bm.block_num
    LEFT JOIN block_orders bo
      ON bf.hadm_id = bo.hadm_id AND bf.block_num = bo.block_num
    LEFT JOIN block_micro bmi
      ON bf.hadm_id = bmi.hadm_id AND bf.block_num = bmi.block_num
    LEFT JOIN block_transfers bt
      ON bf.hadm_id = bt.hadm_id AND bf.block_num = bt.block_num
  )
SELECT * FROM final_dataset;

SELECT * FROM _SESSION.final_dataset_temp
