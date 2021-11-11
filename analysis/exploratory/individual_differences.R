# ---
# title: "Looking at individual differences through KL divergce"
# author: "mcmoyer"
# date: "April 19, 2021"
# ---

# GOAL: quantify the amount of agreement/disagreement item by item
# looking at the sum of KL divergences from each individual to the mean
# each item mean values as the target 
# and compute KL divergence from participant to mean
# 
# sum up all the KL
# and it becomes the item's disagreement value?
# 
# OR take the average of the KL and put error bars?
# 
# by-item mean disagreement rating but also error bars to speak to variability in the disagreement
# 
# Whether there's cross-participant certainty

library(lme4)
library(lmerTest)
library(multcomp) # not available for this version of R
library(tidyverse)
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../helpers.R")

cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")

########################################################################
# Read the data into R.

# Read database
corp = read.table("../../corpus/results/swbd.tab",sep="\t",header=T,quote="")
# Read experimental data in
d_eq = read.csv("../04_experiment/data/exp04_main-merged.csv")
d_rq = read.csv("../03_experiment/data/exp03_main-merged.csv")
d = rbind(d_rq,d_eq)

# rename item_id from corpus file
names(corp)[names(corp) == "Item_ID"] <- "tgrep_id"

# filter from the database the tgrep_ids from the raw data
corp_match = corp %>%
  filter(tgrep_id %in% d$tgrep_id)

# join dfs together
d <- left_join(d, corp_match, by="tgrep_id")
names(d)

d_wide = d %>%
  filter(!tgrep_id %in% c("example1", "example2", "example3", "example4","bot_check")) %>%
  filter(!grepl("control",tgrep_id)) %>%
  spread(paraphrase,rating)

head(d_wide)

ratingVector <- function(x,y,z) {
  
}


d["rating_vector"] = 