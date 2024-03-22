library(tidyverse)
library(googleCloudStorageR)

# pull in data from google cloud ---------------------------------------------------
gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "adult-holding-redd-and-carcass-surveys/clear-creek/data/clear_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "clear_daily_redd.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage_estimate.csv"),
               overwrite = TRUE)

pe-dev-bucket/adult-upstream-passage-monitoring/clear-creek/data/clear_passage.csv

redd_raw <- read.csv(here::here("data-raw", "clear_daily_redd.csv"))

upstream_passage_raw <- read.csv(here::here("data-raw", "standard_adult_passage.csv")) |>
  filter(stream == "clear creek")

upstream_passage_estimate_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream == "clear creek")


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
  glimpse()

up <- upstream_passage_raw |>
  filter(run %in% c("not recorded", "spring", "unknown")) |>
  select(-c(ladder, fork_length, temperature, flow, stream, hours)) |>
  mutate(jack_size = case_when(jack_size == "yes" ~ TRUE,
                               jack_size == "no" ~ FALSE,
                               TRUE ~ NA)) |>
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
write.csv(redd, here::here("data", "clear_redd.csv"), row.names = FALSE)
write.csv(up, here::here("data", "clear_upstream_passage_raw.csv"), row.names = FALSE)
write.csv(up_estimate, here::here("data", "clear_upstream_passage_estimates.csv"), row.names = FALSE)


# save cleaned data to `data/`
read.csv(here::here("data", "clear_redd.csv")) |> glimpse()
read.csv(here::here("data", "clear_upstream_passage_raw.csv")) |> glimpse()
read.csv(here::here("data", "clear_upstream_passage_estimates.csv")) |> glimpse()
