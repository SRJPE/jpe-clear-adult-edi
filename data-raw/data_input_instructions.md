Data Entry Template for Redd Survey Data in Clear Creek
================

**Author**: Badhia Yunes Katz  
**Date**: January 2025

The goal of this document is to provide guidance on data entry for Redd
data entry on Clear Creek. By having a more unified data entry, less
cleaning will be needed, and therefore EDI updates will run smoothly.

## General Guidelines

1.  **Date Format**: Use the format `MM/DD/YYYY` for all dates.
2.  **Consistency in Categories**:
    - Use standardized categories for substrate sizes based on the
      Wentworth Scale.
    - Ensure consistent naming conventions for `REACH`, `SPECIES`, and
      other categorical fields.
3.  **Mandatory Fields**: Enter values for all required fields. Use `NA`
    if a value is not applicable or missing.

\#TODO check these descriptions

| **Field**      | **Data Type (R)** | **Description**                                        | **Allowed Values/Format**                                          |
|----------------|-------------------|--------------------------------------------------------|--------------------------------------------------------------------|
| `method`       | `character`       | Sampling or measurement method used                    | `"Snorkel"`                                                        |
| `point_x`      | `numeric`         | X-coordinate of the point (geographical location)      | Decimal values (e.g., -122.5404)                                   |
| `point_y`      | `numeric`         | Y-coordinate of the point (geographical location)      | Decimal values (e.g., 40.58156)                                    |
| `survey_8`     | `numeric`         | Survey ID or reference for the survey                  | `NA` or numeric                                                    |
| `river_mile`   | `numeric`         | River mile marker of the observation                   | Decimal values                                                     |
| `x1000ftbreak` | `numeric`         | Categorization based on 1000 ft breaks                 | Numeric values (e.g., 87000)                                       |
| `ucc_relate`   | `character`       | Relationship to UCC                                    | `"Above"`, `"Below"`                                               |
| `pw_location`  | `numeric`         | Location based on PW (Programmatic Work)               | Numeric values (e.g., 8.2)                                         |
| `pw_relate`    | `character`       | Relationship to PW                                     | `"Above"`, `"Below"`                                               |
| `date`         | `POSIXct`         | Observation or sampling date                           | Date-time format (e.g., `2000-09-25`)                              |
| `reach`        | `character`       | Designated river reach or area                         | `"R1"`, `"R2"`, `"R3"`, `"R4"`, `"R5"`                             |
| `redd_id`      | `character`       | Identifier for a redd (spawning bed)                   | `NA` or free text                                                  |
| `species`      | `character`       | Species being observed                                 | `"CHINOOK"`                                                        |
| `age`          | `numeric`         | Age of the observed species                            | `NA` or numeric                                                    |
| `redd_loc`     | `character`       | Location of the redd                                   | `NA` or free text                                                  |
| `gravel`       | `character`       | Type of gravel or substrate                            | `"Native"`, `"Combination"`, `"Injection"`                         |
| `inj_site`     | `character`       | Site of inj or observation                             | Free text (e.g., `"Paige Bar"`)                                    |
| `pre_sub`      | `character`       | Pre-substrate condition                                | “\<0.25”, “0.25-0.5”, “0.5-1”, “1-2”, “2-4”, “4-8”, “8-16”, “\>16” |
| `side_sub`     | `character`       | Side-substrate condition                               | Same as `pre_redd_substrate_in`                                    |
| `tail_sub`     | `character`       | Tail-substrate condition                               | Same as `pre_redd_substrate_in`                                    |
| `fish_on_re`   | `character`       | Presence of fish on redd                               | `TRUE`, `FALSE`                                                    |
| `measure`      | `character`       | Redd measurement was taken                             | `TRUE`, `FALSE`                                                    |
| `why_not_me`   | `character`       | Reason for missing measurement                         | `NA` or free text                                                  |
| `date_mea`     | `Date`            | Date measurement was taken                             | `MM/DD/YYYY`                                                       |
| `pre_in`       | `numeric`         | Pre-measurement in inches                              | `NA` or numeric                                                    |
| `pit_in`       | `numeric`         | Pit measurement in inches                              | `NA` or numeric                                                    |
| `tail_in`      | `numeric`         | Tail measurement in inches                             | `NA` or numeric                                                    |
| `length_in`    | `numeric`         | Length in inches                                       | `NA` or numeric                                                    |
| `width_in`     | `numeric`         | Width in inches                                        | `NA` or numeric                                                    |
| `velocity`     | `numeric`         | Water velocity at the measurement site                 | `NA` or numeric                                                    |
| `start_60`     | `numeric`         | Start values on the mechanical flow meter at 60% depth | `NA` or numeric                                                    |
| `end_60`       | `numeric`         | End values on the mechanical flow meter at 60% depth   | `NA` or numeric                                                    |
| `sec_60`       | `numeric`         | Duration meter was in the water at 60% depth           | `NA` or numeric                                                    |
| `start_80`     | `numeric`         | Start values on the mechanical flow meter at 80% depth | `NA` or numeric                                                    |
| `end_80`       | `numeric`         | End values on the mechanical flow meter at 80% depth   | `NA` or numeric                                                    |
| `secs_80`      | `numeric`         | Duration meter was in the water at 80% depth           | `NA` or numeric                                                    |
| `bomb_vel60`   | `numeric`         | Mean water column velocity measured at 60% depth       | `NA` or numeric                                                    |
| `bomb_vel80`   | `numeric`         | Mean water column velocity measured at 80% depth       | `NA` or numeric                                                    |
| `comments`     | `character`       | Additional comments or observations                    | Free text                                                          |
| `date_1`       | `Date`            | Date for the first observation                         | `MM/DD/YYYY`                                                       |
| `age_1`        | `numeric`         | Age recorded for the first observation                 | `NA` or numeric                                                    |
| `date_2`       | `Date`            | Date for the second observation                        | `MM/DD/YYYY`                                                       |
| `age_2`        | `numeric`         | Age recorded for the second observation                | `NA` or numeric                                                    |
| `date_3`       | `Date`            | Date for the third observation                         | `MM/DD/YYYY`                                                       |
| `age_3`        | `numeric`         | Age recorded for the third observation                 | `NA` or numeric                                                    |
| `date_4`       | `Date`            | Date for the fourth observation                        | `MM/DD/YYYY`                                                       |
| `age_4`        | `numeric`         | Age recorded for the fourth observation                | `NA` or numeric                                                    |
| `date_5`       | `Date`            | Date for the fifth observation                         | `MM/DD/YYYY`                                                       |
| `age_5`        | `numeric`         | Age recorded for the fifth observation                 | `NA` or numeric                                                    |
| `date_6`       | `Date`            | Date for the sixth observation                         | `MM/DD/YYYY`                                                       |
| `age_6`        | `numeric`         | Age recorded for the sixth observation                 | `NA` or numeric                                                    |
| `date_7`       | `Date`            | Date for the seventh observation                       | `MM/DD/YYYY`                                                       |
| `age_7`        | `numeric`         | Age recorded for the seventh observation               | `NA` or numeric                                                    |
| `date_8`       | `Date`            | Date for the eighth observation                        | `MM/DD/YYYY`                                                       |
| `age_8`        | `numeric`         | Age recorded for the eighth observation                | `NA` or numeric                                                    |
| `date_9`       | `Date`            | Date for the ninth observation                         | `MM/DD/YYYY`                                                       |
| `age_9`        | `numeric`         | Age recorded for the ninth observation                 | `NA` or numeric                                                    |
| `run`          | `character`       | Description of the fish run                            | Free text                                                          |

## Substrate Classification System

- For the `PRE_SUB`, `SIDE_SUB`, and `TAIL_SUB` fields, **always use the
  standardized size ranges** listed below:

| Standardized Size Range | Substrate Class          |
|-------------------------|--------------------------|
| `<0.25`                 | Fine sand                |
| `0.25-0.5`              | Medium sand              |
| `0.5-1`                 | Coarse sand              |
| `1-2`                   | Very coarse sand         |
| `2-4`                   | Very fine gravel         |
| `4-8`                   | Fine gravel              |
| `8-16`                  | Medium gravel            |
| `>16`                   | Coarse gravel to boulder |

------------------------------------------------------------------------

## Automated Validations

1.  **Substrate Size Consistency**:
    - Ensure all `PRE_SUB`, `SIDE_SUB`, and `TAIL_SUB` values match one
      of the standardized size ranges listed above.
    - Automatically map sizes to their corresponding substrate classes.
2.  **Reach Standardization**:
    - Convert numeric reaches (`1`, `2`, etc.) to the format `R1`, `R2`,
      etc., during processing.
3.  **Missing Data Checks**:
    - Ensure no required fields are left blank. Flag entries with
      missing mandatory values.
4.  **Date Validation**:
    - Verify that `DATE` and `DATE_MEA` are in `MM/DD/YYYY` format.
