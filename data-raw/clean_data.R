library(tidyverse)
library(googleCloudStorageR)

# TODO personnel
# TODO title
# TODO keyword set
# TODO funding
# TODO project
# TODO coverage
# TODO when do we merge in standardized reaches?

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

escapement_raw <- read.csv(here::here("data-raw", "standard_adult_passage.csv")) |>
  filter(stream %in% c("clear creek"))

escapement_estimate_raw <- read.csv(here::here("data-raw", "standard_adult_passage_estimate.csv")) |>
  filter(stream %in% c("clear creek"))

# clean data --------------------------------------------------------------
# here is where we clean up the data and make sure it all looks as expected
# check unique values for each column
# check that all fields are being read in the right way (usually has to do with dates)

#fields "run" and "species" are all "not recorded", opted to delete them
redd <- redd_raw |>
  select(-c(depth_m, starting_elevation_ft, num_of_fish_on_redd, latitude, longitude, pre_redd_substrate_class, tail_substrate_class, redd_substrate_class, ))
glimpse(redd)

up <- escapement_raw |>
  select(-c(time, adipose_clipped, sex, passage_direction, viewing_condition,
            spawning_condition, ladder, hours, comments, jack_size, confidence_in_sex, fork_length, status, dead, temperature, flow)) |>
  glimpse()
#TODO check on flows adn temperature, because all NA's
up_estimate <- escapement_estimate_raw
glimpse(escapement_estimate_raw)

# write files -------------------------------------------------------------
write.csv(redd, here::here("data", "clear_redd.csv"), row.names = FALSE)
write.csv(up, here::here("data", "clear_escapement_raw.csv"), row.names = FALSE)
write.csv(up_estimate, here::here("data", "clear_escapement_estimates_raw.csv"), row.names = FALSE)


# save cleaned data to `data/`
read.csv(here::here("data", "clear_redd.csv")) |> glimpse()
read.csv(here::here("data", "clear_escapement_raw.csv")) |> glimpse()
read.csv(here::here("data", "clear_escapement_estimates_raw.csv")) |> glimpse()
