# Predicting Unplanned Invasive Ventilation in Hospitalized Non-Intensive Care Unit Patients: A Machine Learning Analysis of MIMIC-IV

**Data Mining in Health Care Spring 2026 (HI 780, Spring 2026)**
George Mason University
College of Public Health - Department of Health Administration and Policy

**Students:** Eema Iftikhar & John Lawrence
**Professor:** Abdul Hafeez, PhD

## Overview
- This project develops a machine learning model to predict unplanned intubation among non-ICU inpatients using the MIMIC-IV clinical database.
- Because continuous bedside monitoring data (vitals, nursing assessments) is not available for floor patients in MIMIC-IV, the model relies on laboratory values, medication exposure and admission characteristics, data types that are available for any hospitalized patient regardless of care setting.
- The analysis is implemented in Google BigQuery Studio using a shared Google Cloud project with access to MIMIC-IV v3.1 via PhysioNet.
