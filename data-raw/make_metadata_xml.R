library(EDIutils)
library(tidyverse)
library(EMLaide)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/clear_redd.csv",
                             "data/clear_redd_summary.csv",
                             "data/clear_upstream_passage_raw.csv",
                             "data/clear_upstream_passage_estimates.csv",
                             "data/clear_years_to_include.csv"),
                attribute_info = c("data-raw/metadata/clear_redd_metadata.xlsx",
                                   "data-raw/metadata/clear_redd_summary_metadata.xlsx",
                                   "data-raw/metadata/clear_upstream_passage_raw_metadata.xlsx",
                                   "data-raw/metadata/clear_upstream_passage_estimates_metadata.xlsx",
                                   "data-raw/metadata/clear_years_to_include_metadata.xlsx"),
                datatable_description = c("Daily repeated observation redd survey data",
                                          "Annual redd summary",
                                          "Daily upstream passage data, raw count",
                                          "Yearly passage data, interpolated estimates",
                                          "Description of data caveats"),
                datatable_url = paste0("https://raw.githubusercontent.com/SRJPE/jpe-clear-adult-edi/create-edi/data/",
                                       c("clear_redd.csv",
                                         "clear_redd_symmary.csv",
                                         "clear_upstream_passage_raw.csv",
                                         "clear_upstream_passage_estimates.csv",
                                         "clear_years_to_include.csv")))
# save cleaned data to `data/`
excel_path <- "data-raw/metadata/clear_adult_metadata.xlsx"
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
#methods_docx <- "data-raw/metadata/methods.docx"
methods_md <- "data-raw/metadata/methods.md"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "edi.1865.1"

dataset <- list() |>
  add_pub_date() |>
  add_title(metadata$title) |>
  add_personnel(metadata$personnel) |>
  add_keyword_set(metadata$keyword_set) |>
  add_abstract(abstract_docx) |>
  add_license(metadata$license) |>
  add_method(methods_md) |>
  add_maintenance(metadata$maintenance) |>
  add_project(metadata$funding) |>
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) |>
  add_datatable(datatable_metadata)

# GO through and check on all units
custom_units <- data.frame(id = c("count of fish", "year", "number of redds", "number of reaches"),
                           unitType = c("dimensionless", "dimensionless", "dimensionless", "dimensionless"),
                           parentSI = c(NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA),
                           description = c("number of fish counted", "age of redd in years", "number of redds counted", "number of reaches"))


unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
)
edi_number
EML::write_eml(eml, paste0(edi_number, ".xml"))
EML::eml_validate(paste0(edi_number, ".xml"))

# EMLaide::evaluate_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")
# EMLaide::upload_edi_package(Sys.getenv("user_ID"), Sys.getenv("password"), "edi.1047.1.xml")


# save cleaned data to `data/`
