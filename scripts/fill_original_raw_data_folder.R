# Script reads all model submissions from clone of original repo 
# and saves as parquet in the hub-formatted repo under 
# the original_raw_data folder

# Set destination path (i.e. the hub-formatted repo's original raw data folder)
dest_path = "../../flusight1_hub/original_raw_data/"

# Set the source path (i.e. location of the clone of original repo)
source_path = "../FluSight-forecasts/"

# Vector of seasons
dirs = c("2015-2016", "2016-2017", "2017-2018", "2018-2019", "2019-2020")


for(d in dirs) {
  # create seasonal folder and get all the subfolders (i.e model folders)
  dir.create(paste0(dest_path, d),showWarnings = F)
  sf = list.dirs(paste0(source_path, d))
  for(f in sf) {
    # create the model folder within this seasonal folder and get all the files
    dest_folder = paste0(dest_path, d, "/", basename(f))
    if(!basename(dest_folder) %in% dirs) {
      dir.create(dest_folder, showWarnings = F)
      submissions = list.files(f, "*.csv", full.names = T)
      for(s in submissions) {
        # read the file, and write it as parquet in the destination
        bs = stringr::str_replace(basename(s), ".csv", ".parquet")
        dest_file = paste0(dest_folder, "/", bs)
        arrow::write_parquet(data.table::fread(s), dest_file)
      }
    }
  }
}


