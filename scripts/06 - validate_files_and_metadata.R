library(hubValidations)
library(hubAdmin)

hubAdmin::validate_model_metadata_schema()
hubAdmin::validate_hub_config(hub_path = "./")


## check metadata
metadata_files <- list.files("model-metadata/")

for (file in metadata_files) {
  print(paste("checking", file))
  tmp <- validate_model_metadata(hub_path = "./", 
                          file_path = file)
  print(tmp)
}

## validate
output_files <- list.files("model-output/",recursive = TRUE)

local_validate_model_data <- function (hub_path, file_path, round_id_col = NULL, validations_cfg_path = NULL) {
  checks <- new_hub_validations()
  file_meta <- parse_file_name(file_path)
  round_id <- file_meta$round_id
  checks$file_read <- try_check(check_file_read(file_path = file_path, 
                                                hub_path = hub_path), file_path)
  if (is_any_error(checks$file_read)) {
    return(checks)
  }
  if (fs::path_ext(file_path) == "csv") {
    tbl <- read_model_out_file(file_path = file_path, hub_path = hub_path, 
                               coerce_types = "hub")
  }
  else {
    tbl <- read_model_out_file(file_path = file_path, hub_path = hub_path, 
                               coerce_types = "none")
  }
  checks$valid_round_id_col <- try_check(check_valid_round_id_col(tbl, 
                                                                  round_id_col = round_id_col, file_path = file_path, hub_path = hub_path), 
                                         file_path)
  checks$unique_round_id <- try_check(check_tbl_unique_round_id(tbl, 
                                                                round_id_col = round_id_col, file_path = file_path, hub_path = hub_path), 
                                      file_path)
  if (is_any_error(checks$unique_round_id)) {
    return(checks)
  }
  checks$match_round_id <- try_check(check_tbl_match_round_id(tbl, 
                                                              round_id_col = round_id_col, file_path = file_path, hub_path = hub_path), 
                                     file_path)
  if (is_any_error(checks$match_round_id)) {
    return(checks)
  }
  checks$colnames <- try_check(check_tbl_colnames(tbl, round_id = round_id, 
                                                  file_path = file_path, hub_path = hub_path), file_path)
  if (is_any_error(checks$colnames)) {
    return(checks)
  }
  checks$col_types <- try_check(check_tbl_col_types(tbl, file_path = file_path, 
                                                    hub_path = hub_path), file_path)
  tbl_chr <- read_model_out_file(file_path = file_path, hub_path = hub_path, 
                                 coerce_types = "chr")
  checks$valid_vals <- try_check(check_tbl_values(tbl_chr, 
                                                  round_id = round_id, file_path = file_path, hub_path = hub_path), 
                                 file_path)
  if (is_any_error(checks$valid_vals)) {
    return(checks)
  }
  checks$rows_unique <- try_check(check_tbl_rows_unique(tbl_chr, 
                                                        file_path = file_path, hub_path = hub_path), file_path)
  # checks$req_vals <- try_check(check_tbl_values_required(tbl_chr, 
  #                                                        round_id = round_id, file_path = file_path, hub_path = hub_path), 
  #                              file_path)
  checks$value_col_valid <- try_check(check_tbl_value_col(tbl, 
                                                          round_id = round_id, file_path = file_path, hub_path = hub_path), 
                                      file_path)
  checks$value_col_non_desc <- try_check(check_tbl_value_col_ascending(tbl, 
                                                                       file_path = file_path), file_path)
  checks$value_col_sum1 <- try_check(check_tbl_value_col_sum1(tbl, 
                                                              file_path = file_path), file_path)
  #custom_checks <- execute_custom_checks(validations_cfg_path = validations_cfg_path)
  #combine(checks, custom_checks)
  checks
}

# checklist <- purrr::map(
#  output_files,
#  ~local_validate_model_data(hub_path = "./", 
#                             file_path = .x)
# )


sink("validation_output.txt")
for (file in output_files) {
  # file = output_files[1]
  print(paste("checking", file))
  tmp <- local_validate_model_data(hub_path = "./", 
                          file_path = file)
  lapply(tmp, print)
}
sink()
