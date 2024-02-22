library(tidyverse)
library(googleCloudStorageR)

# TODO personnel
# TODO title
# TODO keyword set
# TODO funding
# TODO project
# TODO coverage

# pull in data from google cloud ---------------------------------------------------
gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
gcs_global_bucket(bucket = Sys.getenv("GCS_DEFAULT_BUCKET"))

gcs_get_object(object_name = "standard-format-data/standard_daily_redd.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_daily_redd.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_upstream_passage.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage.csv"),
               overwrite = TRUE)

gcs_get_object(object_name = "standard-format-data/standard_adult_passage_estimate.csv",
               bucket = gcs_get_global_bucket(),
               saveToDisk = here::here("data-raw", "standard_adult_passage_estimate.csv"),
               overwrite = TRUE)

redd_raw <- read.csv(here::here("data-raw", "standard_daily_redd.csv")) |>
  filter(stream == "clear creek")

upstream_passage_raw <- read.csv(here::here("data-raw", "standard_adult_passage.csv")) |>
  filter(stream %in% c("clear creek"))

upstream_passage_estimate_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream %in% c("clear creek"))

# clean data --------------------------------------------------------------
# here is where we clean up the data and make sure it all looks as expected
# check unique values for each column
# check that all fields are being read in the right way (usually has to do with dates)

# TODO confirm NAs are chinook
redd <- redd_raw |>
  mutate(species = ifelse(is.na(species), "chinook", species)) |>
  filter(species != "steelhead",
         run %in% c("spring", "not recorded")) |>
  select(-c(depth_m, starting_elevation_ft, num_of_fish_on_redd, latitude,
            longitude, species, pre_redd_substrate_class, tail_substrate_class,
            redd_substrate_class, stream, year)) |>
  glimpse()

up <- upstream_passage_raw |>
  select(-c(ladder, hours, comments, confidence_in_sex,
            fork_length, status, dead, temperature, flow,
            stream)) |>
  glimpse()

up_estimate <- upstream_passage_estimate_raw |>
  select(-c(ladder, ucl, lcl, confidence_interval, stream)) |>
  glimpse()

# write files -------------------------------------------------------------
write.csv(redd, here::here("data", "clear_redd.csv"), row.names = FALSE)
write.csv(up, here::here("data", "clear_upstream_passage_raw.csv"), row.names = FALSE)
write.csv(up_estimate, here::here("data", "clear_upstream_passage_estimates.csv"), row.names = FALSE)


# save cleaned data to `data/`
read.csv(here::here("data", "clear_redd.csv")) |> glimpse()
read.csv(here::here("data", "clear_upstream_passage_raw.csv")) |> glimpse()
read.csv(here::here("data", "clear_upstream_passage_estimates.csv")) |> glimpse()
