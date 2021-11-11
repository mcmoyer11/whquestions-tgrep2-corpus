---
title: "Hand Annotating MS Contexts for Domain Restriction"
author: Morgan Moyer
date: May 7, 2021
output: html_document
---

library(ggplot2)
library(lme4)
library(lmerTest)
library(multcomp) # not available for this version of R
library(stringr)
library(textstem)
library(tidyverse)
theme_set(theme_bw())
cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")
this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../../helpers.R")

# Read in the data
data = read.csv("../03_04_together/total_data.csv")
names(data)[names(data) == "tgrep_id"] <- "TGrepID"
contexts = read.csv("../../../corpus/analysis/swbd_contexts.csv")
d <- left_join(data, contexts, by="TGrepID")
d = as.data.frame.matrix(d) 


ex = d %>%
  filter(TGrepID == "132813:10") %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating))
View(ex)

View(d)
agr_ms = d %>%
  distinct() %>%
  filter(paraphrase == "a") %>%
  group_by(TGrepID,Question) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  # filter(mean_rating >= mean(mean_rating)) %>% # this isn't working?
  left_join(., contexts,by="TGrepID")
agr_ms = subset(agr_ms, agr_ms$mean_rating > mean(agr_ms$mean_rating))
agr_ms = as.data.frame(agr_ms)
View(agr_ms)

set.seed(333)
ms_sample = sample_n(agr_ms,100)
View(ms_sample)
nrow(ms_sample)

ms_sample["domain_size_question"] = ""
ms_sample["domain_type_question"] = ""
ms_sample["domain_granularity_question"] = ""
ms_sample["domain_size_context"] = ""
ms_sample["domain_type_context"] = ""
ms_sample["domain_granularity_context"] = ""

# write.csv(ms_sample,"MS_contexts.csv")

agr_ma = d %>%
  distinct() %>%
  filter(paraphrase == "every") %>%
  group_by(TGrepID,Question) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  # filter(mean_rating >= mean(mean_rating)) %>%
  left_join(., contexts,by="TGrepID")
agr_ma = subset(agr_ma, agr_ma$mean_rating > mean(agr_ma$mean_rating))
agr_ma = as.data.frame(agr_ma) 
set.seed(666)
ma_sample = sample_n(agr_ma,100)
View(ma_sample)
ma_sample["domain_size_question"] = ""
ma_sample["domain_type_question"] = ""
ma_sample["domain_granularity_question"] = ""
ma_sample["domain_size_context"] = ""
ma_sample["domain_type_context"] = ""
ma_sample["domain_granularity_context"] = ""
write.csv(agr_ma,"MA_contexts.csv")

