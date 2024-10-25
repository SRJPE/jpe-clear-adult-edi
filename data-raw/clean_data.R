library(tidyverse)
library(googleCloudStorageR)

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

redd_raw <- read.csv(here::here("data-raw", "clear_daily_redd.csv"))

upstream_passage_raw <- readxl::read_xlsx(here::here("data-raw/clear_creek_raw_counts.xlsx"),
                                          sheet = "SR 2_20-9_15")

upstream_passage_estimate_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream == "clear creek")

years_to_include_raw <- readxl::read_xlsx(here::here("data-raw/clear_creek_raw_counts.xlsx"),
                                          sheet = "Metadata",
                                          skip = 15)

# redd --------------------------------------------------------------------
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

unique(redd_raw$redd_substrate_size)

redd_substrate_size_lookup <-
  data.frame("redd_substrate_size" = unique(redd_raw$redd_substrate_size),
             "standardized_size_range" = c(NA, "1-2", "2-4", "1-2",
                                           "2-4", "2-4", "0.5-1", "4-8",
                                           "2-4", "4-8", "4-8", ">16", "8-16")) |>
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

redd <- redd_raw |>
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
  # redd count is 1 for each observation, but unique redd_id must be used to get a total and avoid double counting
  mutate(redd_count = 1) |>
  select(date, redd_id = JPE_redd_id, reach = standardized_reach, fish_on_redd,
         age, run, redd_count,
         redd_measured = measured, redd_width, redd_length, pre_redd_depth, redd_pit_depth,
         redd_tail_depth, pre_redd_substrate_class, redd_substrate_class,
         tail_substrate_class, velocity)

  redd_summary <- redd |>
    mutate(year = year(date)) |>
    group_by(year) |>
    distinct(redd_id, .keep_all = T) |>
    summarize(total_annual_redd_count = sum(redd_count),
              number_reaches_surveyed = length(unique(reach)))
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
  mutate(removed = ifelse(removed == "Removed", TRUE, FALSE)) |>
  glimpse()

up_estimate <- upstream_passage_estimate_raw |>
  select(-c(ladder, stream, adipose_clipped, ucl, lcl, confidence_interval)) |>
  # add stat method from USFWS Adult Spring-run Chinook Salmon Monitoring in Clear Creek, California, 2013-2018 Report
  # https://drive.google.com/drive/u/0/folders/1vv_QV9NdiIc4tlWPPB3UBs1s8idBOiSB
  mutate(stat_method = case_when(year %in% c(2013:2016, 2018) ~ "generalized additive model (GAM)",
                                 year == 2017 ~ "raw data",
                                 TRUE ~ "not recorded")) |>
  glimpse()

# write files -------------------------------------------------------------
write_csv(redd, here::here("data", "clear_redd.csv"))
write_csv(redd_summary, here::here("data", "clear_redd_summary.csv"))
write_csv(up, here::here("data", "clear_upstream_passage_raw.csv"))
write_csv(up_estimate, here::here("data", "clear_upstream_passage_estimates.csv"))


# save cleaned data to `data/`
# read.csv(here::here("data", "clear_redd.csv")) |> glimpse()
# read.csv(here::here("data", "clear_upstream_passage_raw.csv")) |> glimpse()
# read.csv(here::here("data", "clear_upstream_passage_estimates.csv")) |> glimpse()
