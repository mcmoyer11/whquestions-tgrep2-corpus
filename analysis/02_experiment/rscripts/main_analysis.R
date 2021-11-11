# ---
# title: "Analysis of questions"
# author: "mcmoyer"
# date: "November 20, 2020"
# ---

## Step 1: select stimuli for experiment
library(ggplot2)
library(tidyr)
library(dplyr)
library(lme4)
library(lmerTest)
library(tidyverse)
library(multcomp) # not available for this version of R
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../../helpers.R")

cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")

########################################################################
# Read the data into R.
d = read.csv("../data/normed.csv")

contrasts(d$ModalPresent)
contrasts(d$Wh) = cbind("how.vs.where"=c(1,0,0),"who.vs.where"=c(0,0,1))
contrasts(d$paraphrase) = cbind("a.vs.every"=c(1,0,0),"the.vs.every"=c(0,0,1))

# Full Model with random slopes
m = lmerTest::lmer(rating ~ ModalPresent*Wh*paraphrase + (1+paraphrase|workerid) + (1+paraphrase|tgrep_id), data=d,REML=FALSE) 
# message?: boundary (singular) fit: see ?isSingular
summary(m)

m.twowayinteraction = lmer(rating ~ ModalPresent+Wh+paraphrase + ModalPresent:paraphrase + Wh:paraphrase + (1+paraphrase|workerid) + (1+paraphrase|tgrep_id), data=d,REML=FALSE) 
summary(m.twowayinteraction)


########################################################################
# mean center modalpresent (2-level variables only)


# d$ModalPresent[d$ModalPresent == "no"] = "0"
# d$ModalPresent[d$ModalPresent == "yes"] = "1"

str(d)
centered = cbind(d,myCenter(d["ModalPresent"]))

head(centered)
summary(centered)
str(centered)

# full model with random slopes
m.twowayinteraction.centered = lmerTest::lmer(rating ~ cModalPresent+Wh+paraphrase + cModalPresent:paraphrase + Wh:paraphrase + (1+paraphrase|workerid) + (1+paraphrase|tgrep_id), data=centered,REML=FALSE) 
summary(m.twowayinteraction.centered)
