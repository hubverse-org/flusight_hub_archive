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
