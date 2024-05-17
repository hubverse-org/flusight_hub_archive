rm(list=ls())
library(data.table)
library(here)

#DEFAULT_FLUSIGHT_REPO_PATH = "../"

# repos <- function(path = here("../HubRepos/")) {
#   return(list.dirs(path = path, full.names = T, recursive = F))
# }
# need repo-specific functions to pull the data
repo_FluSight_forecasts_pull <- function(years=NULL, path_to_flusight_forecasts = "../original_raw_data/") {
  
  get_years <- function(path_to_flusight_forecasts) {
    fs_dirs = list.dirs(path_to_flusight_forecasts)
    m = regexpr("20\\d{2}-20\\d{2}", fs_dirs)
    return(unique(regmatches(fs_dirs, m)))
  }
  
  if(is.null(years)) {
    years = get_years(path_to_flusight_forecasts)
  }

  rbindlist(
    lapply(years, \(y) repo_FluSight_forecasts_pull_year(y, path_to_flusight_forecasts)[, yr:=y]),
    use.names = T
  )

}

repo_FluSight_forecasts_pull_year <- function(y, path = "../original_raw_data/") {
  cat("Consolidating ", y, "\n")
  path = paste0(path, y)
  model_paths = list.dirs(path, full.names = T, recursive = F)
  rbindlist(
    lapply(model_paths, \(mp) pull_data_for_model(mp)[, model:=basename(mp)]),
    fill = T,
    use.names = T
  )
}

pull_data_for_model <- function(pth) {
  fnames = list.files(pth, pattern = ".parquet", full.names = T)
  rbindlist(
    lapply(fnames, \(f) {
      #d = data.table::fread(f, colClasses = list("double"=c("Value","value")))[, src:=basename(f)]
      d = dplyr::collect(arrow::read_parquet(f))
      setDT(d)[, src:=basename(f)]
      setnames(d, new=tolower(names(d)))
      d = d[location!=""]
      }), fill = T, use.names = T
  )
}

data = repo_FluSight_forecasts_pull()
data = unique(data)
data[, id:=.I]
#arrow::write_parquet(data, "raw_flusight_data")

