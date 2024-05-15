# FluSight Forecasts (Hubverse Version)

This repo contains the original FluSight Forecast submissions (<https://github.com/cdcepi/FluSight-forecasts>), reformatted to align with the hubverse format. For further detailed information on the original submissions and the content/format of the original files, refer to the repository above.

## Original Submissions

Submissions were submitted by modeling teams and organized within season by the name or number of the submitting team; within each team-specific or model-specific folder, a series of .csv submissions were stored, with file names typically (but not always) in the format: \"EWXX-TeamXX-YYYY-MM-DD.csv\", where

-   **EWXX** is the latest MMWR week of data used in the forecast

-   **TeamXX** is the team name/number

-   **YYYY-MM-DD** is the date of forecast submission

There were four types of targets related to influenza-like illness: season onset, peak week, peak percentage, and week ahead forecasts (1, 2, 3, and weeks) of weighted ILINet percentage

A copy of all original submissions, organized by season/team (e.g. `2015-2016/TeamXX/`) can be found in `original_raw_data/`. All of the original submissions are stored in parquet format

## Conversion Approach

**To do**


## Scripts

Scripts to reproduce the steps taken to create this hubverse formatted version of the repo can be found in the `scripts/` folder.

## Acknowledgments

This repository follows the guidelines and standards outlined by the [hubverse](%5Burl%5D(https://hubdocs.readthedocs.io/en/latest/)), which provides a set of data formats and open source tools for modeling hubs.
