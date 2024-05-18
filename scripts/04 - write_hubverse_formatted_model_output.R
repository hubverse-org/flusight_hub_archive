# Script writes the model_output files
# Note: the script depends on being run directly after
# 03 - convert_raw_flusight_data_to_hubverse_format


# Remove everything except the df created by the parent script and
# remove garbage
rm(list=setdiff(ls(), "df"))
gc()

# Add the standardize lookup
std_names_lookup = fread("standard_model_team_names.csv")
df <- df[std_names_lookup, on="model"]
df[, model:=std_model_id]
df[, std_model_id:=NULL]
gc()

# get the unique rounds
rounds = df[, unique(origin_date)]

# For each round, we will get the models for that round, pull the 
# data for that round and model, select the requisite columns
# and write to a parquet file in that model folder
purrr::walk(rounds, \(r) {
  models = df[origin_date==r, unique(model)]
  purrr::walk(models, \(m) {
    
    # make destination path, and create directory if necessary
    dest_path = paste0("../model-output/", m)
    if(dir.exists(dest_path) == FALSE) dir.create(dest_path)
    
    # get the subset of the data for this round and model
    d = df[
      origin_date==r & model==m,
      .(origin_date, origin_epiweek, location, target, horizon, output_type, output_type_id,value)
    ]
    # create destination filename
    dest_fname = paste0(dest_path, "/", r, "-", m, ".parquet")
    
    # write file
    write_parquet(d, dest_fname)
  })
})
