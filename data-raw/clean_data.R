library(tidyverse)
library(googleCloudStorageR)
library(janitor)

# pull in data from google cloud ---------------------------------------------------
gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "adult-holding-redd-and-carcass-surveys/clear-creek/data/clear_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "clear_daily_redd.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "adult-upstream-passage-monitoring/clear-creek/data-raw/CCVS_SR_EDI.xlsx",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "clear_creek_raw_counts.xlsx"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage_estimate.csv"),
               overwrite = TRUE)

# Notes from Teresa
# We had zero spring-run redds in 2023.
#
# I also found a couple errors for total redds on the "clear_redd_summary.csv" file,
# most likely due to an error in how our database flags redd location.
# There should be 49 redds for 2007, and 10 redds for 2010. These numbers have been
# checked against annual monitoring reports for accuracy. On the "clear_redd.csv" file,
# the four redd_ids "2007_797" through "2007_800" are not attributed to spring-run and can
# be removed. The data for the additional redd in 2010 is also attached.
#
# Additionally, we feel that only data from 2003 and later should be used, as that
# was the first year a temporary barrier weir was constructed to physically separate
# spring-run and fall-run spawning grounds after hybridization was observed. All data
# prior to 2003 does not distinguish between runs and would not be comparable.
redd_raw <- read.csv(here::here("data-raw", "clear_daily_redd.csv"))

redd_2020_raw <- read_csv(here::here("data-raw","Clear_Creek_2020_SCS_redds.csv"))

redd_2022_raw <- read_csv(here::here("data-raw","Clear_Creek_2022_SCS_redds.csv"))
#TODO addd redd data for 2024


# this is the one additional redd that was missing
# i think this was filtered out because of picket weir relation is below?
redd_2010_raw <- read_csv(here::here("data-raw","Clear_Creek_2010_additional_redd.csv"))

upstream_passage_raw <- readxl::read_xlsx(here::here("data-raw/clear_creek_raw_counts.xlsx"),
                                          sheet = "SR 2_20-9_15")

# upstream_passage_estimate_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
#   filter(stream == "clear creek")

upstream_passage_estimate_raw <- read.csv(here::here("data-raw", "clear_upstream_passage_estimates.csv"))

years_to_include_raw <- readxl::read_xlsx(here::here("data-raw/clear_creek_raw_counts.xlsx"),
                                          sheet = "Metadata",
                                          skip = 15)

# redd --------------------------------------------------------------------

# We need to get the new 2020 and 2022 data in the same format as the other years
# The cleaning was previously done in SRJPEdatasets

redd_2020_2022_raw <- bind_rows(redd_2020_raw, redd_2022_raw, redd_2010_raw)
cleaner_data <- redd_2020_2022_raw |>
  janitor::clean_names() |>
  rename('longitude' = 'point_x',
         'latitude' = 'point_y',
         'survey' = 'survey_16',
         'picket_weir_location' = 'pw_location',
         'picket_weir_relation' = 'pw_relate',
         'pre_redd_substrate_size' = 'pre_sub',
         'redd_substrate_size' = 'side_sub',
         'tail_substrate_size' = 'tail_sub',
         'fish_on_redd' = 'fish_on_re',
         'pre_redd_depth' = 'pre_in',
         'redd_pit_depth' = 'pit_in',
         'redd_tail_depth' = 'tail_in',
         'redd_length_in' = 'length_in',
         'redd_width_in' = 'width_in',
         'surveyed_reach' = 'reach',
         'why_not_measured' = 'why_not_me',
         'date_measured' = 'date_mea',
         'measured' = 'measure',
         "survey_method" = "method"
  ) |>
  mutate(date = as.Date(date),
         date_measured = as.Date(date_measured, tryFormats = "%m/%d/%Y"),
         survey = as.character(survey),
         fish_on_redd = case_when(fish_on_redd %in% c("YES", "Yes") ~ TRUE,
                                  fish_on_redd %in% c("No", "NO") ~ FALSE),
         measured = ifelse(measured == "YES", TRUE, FALSE),
         run = ifelse(picket_weir_relation == "Above" & species %in% c("CHINOOK", "Chinook"), "Spring", run)) |>
  select(-c('qc_type','qc_date','inspector','year', 'flow_devic','bomb_id')) |> #all method is snorkel, year could be extracted from date, river_latlong same as rivermile
  select(-c(reach_2, date_2_2, age_2_2, survey_77, survey_2_age, survey_13, survey_74,
            survey_3_age, survey_4_age, survey_5_age, survey_6_age, survey_7_age, survey_8_age, survey_9_age)) |>
  glimpse()

redd_with_age <- cleaner_data |>
  mutate(date = as.Date(date, tryFormats = "%m/%d/%Y"),
         date_2 = as.Date(date_2, tryFormats = "%m/%d/%Y"),
         date_3 = as.Date(date_3, tryFormats = "%m/%d/%Y"),
         date_4 = as.Date(date_4, tryFormats = "%m/%d/%Y"),
         date_5 = as.Date(date_5, tryFormats = "%m/%d/%Y"),
         date_6 = as.Date(date_6, tryFormats = "%m/%d/%Y"),
         date_7 = as.Date(date_7, tryFormats = "%m/%d/%Y"),
         date_8 = as.Date(date_8, tryFormats = "%m/%d/%Y"),
         date_9 = as.Date(date_9, tryFormats = "%m/%d/%Y"),
         year = year(date),
         #year = year(date),
         JPE_redd_id = paste0(date, "_", surveyed_reach, "_", redd_id),
         # take date and age columns and assign to age_1 and survey_1
         age_1 = ifelse(is.na(age_1), age, age_1),
         date_1 = date) |> # they are the same
  pivot_longer(cols = c(age_1, age_2, age_3, age_4, age_5, age_6, age_7, age_8, age_9), # pivot all aging instances to age column
               values_to = "new_age",
               names_to = "age_index") |>
  # for all aging instances, take the date where that aging occurred.
  # check for what aging instance it was and pull that date (if present)
  mutate(new_date = case_when(age_index == "age_1" & !is.na(date_1) ~ date_1,
                              age_index == "age_2" & !is.na(date_2) ~ ymd(date_2),
                              age_index == "age_3" & !is.na(date_3) ~ ymd(date_3),
                              age_index == "age_4" & !is.na(date_4) ~ ymd(date_4),
                              age_index == "age_5" & !is.na(date_5) ~ ymd(date_5),
                              age_index == "age_6" & !is.na(date_6) ~ ymd(date_6),
                              age_index == "age_7" & !is.na(date_7) ~ ymd(date_7),
                              age_index == "age_8" & !is.na(date_8) ~ ymd(date_8),
                              age_index == "age_9" & !is.na(date_9) ~ ymd(date_9),
                              TRUE ~ NA),
         age_index = as.integer(substr(age_index, 5, 5)),
         age_index = ifelse(is.na(new_age) & age_index == 1, 0, age_index)) |>
  filter(!is.na(new_date)) |>
  select(-c(date, age, date_1, date_2, date_3, date_4, date_5,
            date_6, date_7, date_8, date_9, redd_id, comments, year)) |>
  rename(age = new_age, date = new_date) |>
  mutate(species = case_when(species == "CHINOOK" ~ "Chinook",
                             species == "P. LAMPREY" ~ "P. lamprey",
                             TRUE ~ species),
         run = str_to_lower(run)) |>
  relocate(date, .before = survey_method) |>
  relocate(c(age, age_index), .before = gravel) |>
  relocate(JPE_redd_id, .before = date) |>
  glimpse()

# merge 2020-2022 with older
redd_raw_combined <- bind_rows(redd_raw |>
                                 mutate(date = as.Date(date, tryFormats = "%Y-%m-%d"),
                                        date_measured = as.Date(date, tryFormats = "%Y-%m-%d")),
                               redd_with_age |>
                                 mutate(survey = as.numeric(survey))) |>
  mutate(picket_weir_relation = tolower(picket_weir_relation))
# standardize substrate sizes for redd using the Wentworth Scale, created by W.C Krumbein
# when the size range fell into two categories, they were rounded down

# standarized size ranges lookup
substrate_class = data.frame("standardized_size_range" = c("<0.25",
                                                           "0.25-0.5",
                                                           "0.5-1",
                                                           "1-2",
                                                           "2-4",
                                                           "4-8",
                                                           '8-16',
                                                           ">16"),
                             "redd_substrate_class" = c("fine sand",
                                                        "medium sand",
                                                        "coarse sand", "very coarse sand",
                                                        "very fine gravel", "fine gravel",
                                                        "medium gravel",
                                                        "coarse gravel to boulder"))

unique(redd_raw_combined$redd_substrate_size)

redd_substrate_size_lookup <-
  data.frame("redd_substrate_size" = unique(redd_raw_combined$redd_substrate_size),
             "standardized_size_range" = c(NA, "1-2", "2-4", "1-2",
                                           "2-4", "2-4", "0.5-1", "4-8",
                                           "2-4", "4-8", "4-8", ">16", "8-16",
                                           "2-4","1-2","2-4","4-8","<0.25","0.5-1"
                                           )) |>

  left_join(substrate_class)

# standardize the reaches
gcs_get_object(
  object_name = "jpe-model-data/standard_reach_lookup.csv",
  bucket = gcs_get_global_bucket(),
  saveToDisk = here::here("data-raw",  "standard-reach-lookup.csv"),
  overwrite = TRUE
)

standard_reach_lookup <- read_csv(here::here("data-raw",  "standard-reach-lookup.csv")) |>
  filter(stream == "clear creek") |>
  select(reach, standardized_reach)

redd <- redd_raw_combined |>
  filter(species == "Chinook",
         picket_weir_relation == "above") |>
  left_join(redd_substrate_size_lookup |>
              select(redd_substrate_size, redd_substrate_class),
            by = c("redd_substrate_size")) |>
  left_join(redd_substrate_size_lookup |>
              select(redd_substrate_size, tail_substrate_class = redd_substrate_class),
            by = c("tail_substrate_size" = "redd_substrate_size")) |>
  left_join(redd_substrate_size_lookup |>
              select(redd_substrate_size, pre_redd_substrate_class = redd_substrate_class),
            by = c("pre_redd_substrate_size" = "redd_substrate_size")) |>
  left_join(standard_reach_lookup, by = c("surveyed_reach" = "reach")) |>
  select(date, redd_id = JPE_redd_id, reach = standardized_reach, fish_on_redd,
         age, run,
         redd_measured = measured, redd_width, redd_length, pre_redd_depth, redd_pit_depth,
         redd_tail_depth, pre_redd_substrate_class, redd_substrate_class,
         tail_substrate_class, velocity) |>
  # remove redds that according to Teresa are not spring run
  filter(!redd_id %in% c("2007_797", "2007_798",
                         "2007_799", "2007_800"))

  redd_summary <- redd |>
    mutate(year = year(date)) |>
    group_by(year) |>
    distinct(redd_id, .keep_all = T) |>
    mutate(redd_count = 1) |>
    summarize(total_annual_redd_count = sum(redd_count),
              number_reaches_surveyed = length(unique(reach))) |>
    # add row for 2023 where no redds were found
    add_row(year = 2023,
            total_annual_redd_count = 0,
            number_reaches_surveyed = 5)
# upstream passage --------------------------------------------------------

up <- upstream_passage_raw |>
    janitor::clean_names() |>
    rename(brood_year = video_year) |>
    mutate(time_block = format(time_block, "%H:%M:%S"),
           time_passed = format(time_passed, "%H:%M:%S"),
           viewing_condition = case_when(viewing_condition == 0 ~ "clear",
                                         viewing_condition == 1 ~ "light turbidity to turbid",
                                         viewing_condition == 2 ~ "turbid to extreme turbidity",
                                         viewing_condition == 3 ~ "flooded",
                                         TRUE ~ "unknown"),
           adipose_clipped = str_to_lower(adipose),
           adipose_clipped = case_when(adipose_clipped == "present" ~ FALSE,
                                       adipose_clipped == "absent" ~ TRUE,
                                       TRUE ~ NA),
           sex = str_to_lower(sex),
           sex = ifelse(sex == "unk", "unknown", sex),
           spawning_condition = case_when(spawning_condition == 1 ~ "energetic, bright or silvery, non spawning coloration or developed secondary sex characteristics",
                                          spawning_condition == 2 ~ "energetic, can tell sex from secondary characteristics, silvery or bright coloration but may have hints of spawning colors",
                                          spawning_condition == 3 ~ "spawning colors, defined kype, some tail wear or small amount sof fungus",
                                          spawning_condition %in% c(4, 5) ~ "fungus, lethargic, wandering, zombie fish; significant tail wear in females to indicate spawning in progress or has been completed",
                                          TRUE ~ as.character(spawning_condition)),
           jack_size = case_when(jack_size %in% c("YES", "Yes") ~ TRUE,
                                 jack_size %in% c("NO", "No") ~ FALSE,
                                 TRUE ~ NA),
           species = ifelse(species == "CHN", "chinook", species)) |>
    relocate(brood_year, .after = time_block) |>
    pivot_longer(c(up, down), names_to = "passage_direction", values_to = "count") |>
    relocate(count, .after = brood_year) |>
    relocate(passage_direction, .after = count) |>
    select(-adipose) |>
    mutate(run = "spring") |>
    glimpse()

# TODO how to include this information in the edi package?
years_to_include <- years_to_include_raw |>
  rename(brood_year = `Brief Year Description`,
         removed = `...2`,
         description = `...3`) |>
  mutate(removed = ifelse(removed == "Removed", TRUE, FALSE),
         brood_year = as.numeric(paste0("20",brood_year))) |>
  glimpse()

# up_estimate <- upstream_passage_estimate_raw |>
#   select(-c(ladder, stream, adipose_clipped, ucl, lcl, confidence_interval)) |>
#   # add stat method from USFWS Adult Spring-run Chinook Salmon Monitoring in Clear Creek, California, 2013-2018 Report
#   # https://drive.google.com/drive/u/0/folders/1vv_QV9NdiIc4tlWPPB3UBs1s8idBOiSB
#   mutate(stat_method = case_when(year %in% c(2013:2016, 2018) ~ "generalized additive model (GAM)",
#                                  year == 2017 ~ "raw data",
#                                  TRUE ~ "not recorded")) |>
#   glimpse()

# Adding 2024 data that was shared by Samuel Proving in Jan 14
row_2024 <- data.frame(
  year = 2024,
  run = "spring",
  passage_estimate = 6,
  Method_Correction = "", #TODO check if these two rows should be empty
  stat_method = "")

upstream_passage_estimate_bind <- rbind(upstream_passage_estimate_raw, row_2024)


up_estimate <- upstream_passage_estimate_bind |>
  clean_names() |>
  select(-c(stat_method)) |>
  mutate(stat_method = tolower(method_correction)) |>
  select(-method_correction) |>
  glimpse()

# Badhia's notes: I noted some dates that are no in a date format (0010-03-20)
# redd_pit depth max is now 45, it was 2.4 before, we might want to check if this is a typo
# redd_summary year format is off (probably 2021)

# write files -------------------------------------------------------------
write_csv(redd, here::here("data", "clear_redd.csv"))
write_csv(redd_summary, here::here("data", "clear_redd_summary.csv"))
write_csv(up, here::here("data", "clear_upstream_passage_raw.csv"))
write_csv(up_estimate, here::here("data", "clear_upstream_passage_estimates.csv"))
write_csv(years_to_include, here::here("data","clear_years_to_include.csv"))


# save cleaned data to `data/`
# read.csv(here::here("data", "clear_redd.csv")) |> glimpse()
# read.csv(here::here("data", "clear_upstream_passage_raw.csv")) |> glimpse()
# read.csv(here::here("data", "clear_upstream_passage_estimates.csv")) |> glimpse()
