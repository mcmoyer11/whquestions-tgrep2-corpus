# ---
# title: "Analysis of questions"
# author: "mcmoyer"
# date: "November 20, 2020"
# output: html_document
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
cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")


this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)
source("../../helpers.R")
########################################################################
# Read the database into R.
corp = read.table("../../../corpus/results/swbd.tab",sep="\t",header=T,quote="")
# Read the data into R.
d1 = read.csv("../data/main-merged.csv")
nrow(d1)
d2  = read.csv("../data/main2-merged.csv")
nrow(d2)
d3 = rbind(d1,d2)
nrow(d3)
########################################################################
# Rename the Item_ID variable in the database to Tgrep_ID
names(corp)[names(corp) == "Item_ID"] <- "tgrep_id"

# filter from the database the tgrep_ids from the data
corp_match = corp %>%
  filter(tgrep_id %in% d3$tgrep_id)

nrow(corp)
nrow(d1)
nrow(corp_match)


# join the two dataframes together 
d <- left_join(d3, corp_match, by="tgrep_id")
length(unique(d$workerid)) # 385

nrow(d)
d$time_in_minutes = as.numeric(as.character(d$time_in_minutes))
d$rating = as.numeric(d$rating)
# write.csv(df,"df_nested.csv")

head(d)
# until i can find a way to unnest, save this as csv and unnest in python,
# then read the csv back in here
str(d)


# read in the contexts too:
d_contexts = read.csv("../../experiments/clean_corpus/pilot2.txt",sep="\t",header=T,quote="")


########################################################################
########################################################################
# comments and demographic information
########################################################################
########################################################################
length(unique(d$workerid)) #385

# look at comments
unique(d$subject_information.comments)

# fair price
ggplot(d, aes(x=subject_information.fairprice)) +
  geom_histogram(stat="count")
table(d$subject_information.fairprice)

# overall assessment
ggplot(d, aes(x=subject_information.enjoyment)) +
  geom_histogram(stat="count")

# gender
ggplot(d, aes(x=subject_information.gender)) +
  geom_histogram(stat="count")

# education
ggplot(d, aes(x=subject_information.education)) +
  geom_histogram(stat="count")


# time_in_minutes
ggplot(d, aes(x=time_in_minutes)) +
  geom_histogram(stat="count")
mean(d$time_in_minutes)

########################################################################
########################################################################
# Practice trials
# TODO: look at just the first choice items
# Note Date: 12/2
########################################################################
########################################################################
# Practice trials
practice = d %>%
  filter(tgrep_id %in% c("example1", "example2", "example3", "example4"))
  # write.csv(.,"practice_01_pilot_e01.csv")
nrow(practice) #10096

# look at just the first practice trial
prac_agr = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count))
nrow(prac_agr) # 6102

prac_agr_rem = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count)) %>%
  filter(total_per_ex > 4)
  # write.csv(.,"practice_to_edit.csv")
nrow(prac_agr_rem) # 2014

# fixed = read.csv("practice_edited.csv",header=TRUE)
nrow(fixed) # 68
head(fixed)
# remove that one column
# fixed = fixed[c(2:7)]

head(fixed)
prac_agr_keep = practice %>%
  group_by(workerid,tgrep_id,paraphrase,rating) %>%
  summarise(count = n()) %>%
  group_by(workerid,tgrep_id) %>%
  mutate(total_per_ex = sum(count)) %>%
  filter(total_per_ex <= 4)
nrow(prac_agr_keep) # 4088

practice_first = rbind(fixed,prac_agr_keep)
nrow(practice_first) #320


agr = practice %>%
  group_by(tgrep_id, paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()
# View(agr)

labels = c("Who can help spread the word?","Where can I get coffee around here?","Who came to the party?","How do I get to Central Park?")
names(labels) = c("example1","example2","example3", "example4")
# View(labels)
ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge") +
  facet_wrap(~tgrep_id,labeller = labeller(tgrep_id = labels))
ggsave("../graphs/main_practice_total.pdf")
# theme(axis.text.x = element_text(angle = 90))


########################################################################
########################################################################
# Control Items
########################################################################
########################################################################
nrow(d)
controls = d %>%
  filter(grepl("control",tgrep_id))
nrow(controls) # 9240
# read in the file to have access to the items
cntrls = read.csv("../../experiments/clean_corpus/controls.csv",header=TRUE,quote="")
# rename the item column in order to merge on it
names(cntrls)[names(cntrls) == "TGrepID"] <- "tgrep_id"
# join dfs together
c <- left_join(controls, cntrls, by="tgrep_id")

agr = c %>%
  group_by(EntireSentence,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge") +
  facet_wrap(~EntireSentence, labeller = labeller(Sentence = label_wrap_gen(1)))
ggsave("../graphs/main_controls.pdf")

########################################################################
########################################################################
# remove subjects who failed 2/6 controls
########################################################################
########################################################################
length(unique(d$workerid)) #385
unique(c$tgrep_id)
# [1] "movie"   "novels"  "tissue"  "book"    "napkin"  "cookies"
#       the       all         a       the         a         all
t = c %>%
  separate(tgrep_id,into=c("tgrep_id","para","trial"),sep="[_]") %>%
  group_by(workerid,paraphrase,trial) %>%
  filter(trial %in% c("movie", "book"), paraphrase %in% c("the")) %>%
  mutate(control_passed = ifelse(rating > .5,"1","0"))
nrow(t) #770
a1 = c %>%
  separate(tgrep_id,into=c("tgrep_id","para","trial"),sep="_") %>%
  group_by(workerid,paraphrase,trial) %>%
  filter(trial %in% c("novels", "cookies"), paraphrase %in% c("all")) %>%
  mutate(control_passed = ifelse(rating > .5,"1","0"))
nrow(a1) #770
a2 = c %>%
  separate(tgrep_id,into=c("tgrep_id","para","trial"),sep="_") %>%
  group_by(workerid,paraphrase,trial) %>% 
  filter(trial %in% c("tissue", "napkin"), paraphrase %in% c("a")) %>%
  mutate(control_passed = ifelse(rating > .5,"1","0"))
nrow(a2) #770
con = rbind(t,a1,a2)
nrow(con) #2310

########################################################################
# filter out participants who failed more than 2 controls
failed_controls = con %>%
  filter(control_passed == "1") %>%
  group_by(workerid, control_passed) %>%
  summarise(sum_control_passed = n()) %>%
  filter(sum_control_passed < 4)

length(unique(failed_controls$workerid)) # 19
length(unique(failed_controls$workerid))/length(unique(d$workerid))*100 # 4.9%

########################################################################
########################################################################
# Test Items
########################################################################
########################################################################
# N before removing ppl who failed 2 controls 
length(unique(d$workerid)) #385

test = d %>%
  filter(!workerid %in% c(failed_controls$workerid)) %>%
  filter(!tgrep_id %in% c("example1", "example2", "example3", "example4","bot_check")) %>%
  filter(!grepl("control",tgrep_id))
# rename all to every
test$paraphrase[test$paraphrase == "all"] = "every"
unique(test$proliferate.condition)

length(unique(test$workerid)) #366


test[is.na(test)] <- 0

agr = test %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge", show.legend = FALSE) +
  # ggtitle("Overall mean rating for each paraphrase") +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  theme(legend.position = "none")
ggsave("../graphs/main_test_overall.pdf")

agr = test %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=ModalPresent)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh)
ggsave("../graphs/main_test_ModxWh.pdf")


########################################################################
########################################################################
# Normalize the data by removing rhetorical questions 
# (questions with "other" as the highest rating)
########################################################################
########################################################################
test_agr = test %>%
  group_by(tgrep_id, paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating))

other_ratings = test %>%
  group_by(tgrep_id, paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  filter((mean_rating[paraphrase == "other"] > mean_rating[paraphrase=="a"]) & 
           (mean_rating[paraphrase == "other"] > mean_rating[paraphrase=="every"]) & 
           (mean_rating[paraphrase == "other"] > mean_rating[paraphrase=="the"]))

nrow(other_ratings)/nrow(test_agr)*100 # 17.3%
nrow(test_agr)#1340

or_ids = other_ratings$tgrep_id
test_other = test %>%
  filter(tgrep_id %in% or_ids)

# 16% of the items which are rhetorical questions
nrow(test_other)/nrow(test)*100

# filter out those bad guys
test_norm = test %>%
  filter(!tgrep_id %in% or_ids)
nrow(test_norm)/nrow(test)*100 # 82.76%

agr = test_norm %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge", show.legend = FALSE) +
  # ggtitle("Overall mean rating for each paraphrase") +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  theme(legend.position = "none")
ggsave("../graphs/main_test_norm_overall.pdf")

agr = test_norm %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=ModalPresent)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
ggsave("../graphs/main_test_norm_ModxWh.pdf")


agr = test_norm %>%
  group_by(paraphrase) %>%
  filter(paraphrase %in% c("every","a","the")) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge", show.legend = FALSE) +
  # ggtitle("Mean rating for 'a' vs. 'every'") +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  theme(legend.position = "none")
ggsave("../graphs/main_test_aXeverxthey.pdf")

########################################################################
########################################################################
# WH
########################################################################
########################################################################
agr = test_norm %>%
  filter(paraphrase %in% c("every","a","the")) %>%
  group_by(paraphrase,Wh) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=Wh, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9))  +
  # ggtitle("Mean rating for Wh-Word") +
  xlab("Wh-Word") +
  ylab("Mean rating") +
  theme(legend.title = element_blank()) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal")
  # theme(legend.position = "none")
  # facet_wrap(~Wh)
ggsave("../graphs/main_Wh_allXa.pdf")

agr = test_norm %>%
  filter(paraphrase %in% c("every","a")) %>%
  group_by(paraphrase,Wh,Question) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(agr, aes(x=mean_rating)) +
  geom_histogram() +
  facet_grid(Wh~paraphrase)

########################################################################
########################################################################
# Modal
########################################################################
########################################################################
agr = test_norm %>%
  filter(paraphrase %in% c("every","a", "the")) %>%
  group_by(paraphrase,ModalPresent) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=ModalPresent, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  # ggtitle("Mean rating ModalPresent") +
  xlab("Modal Present") +
  ylab("Mean rating") +
  theme(legend.title = element_blank()) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal")
        # legend.spacing.y = unit(-10, 'cm'))
  # guides(fill=guide_legend(title="Paraphrase"))
ggsave("../graphs/main_ModalPresent_allXaxthe.pdf")

# rename 'ca' in modals to 'can'
test_norm$Modal[test_norm$Modal == "ca"] = "can"
mod = test_norm %>%
  filter(paraphrase %in% c("every","a")) %>%
  filter(ModalPresent %in% c("yes")) %>%
  group_by(Modal,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(mod, aes(x=paraphrase,y=mean_rating,fill=paraphrase)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Modal)
ggsave("../graphs/main_modals_allXa.pdf")

########################################################################
# MODAL x WH
########################################################################
agr = test_norm %>%
  filter(paraphrase %in% c("every","a")) %>%
  # filter(ModalPresent %in% c("yes")) %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=ModalPresent)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh) +
  guides(fill=guide_legend(title="Modal?"))
ggsave("../graphs/main_test_norm_ModalsxWh_allXa.pdf")

agr = test_norm %>%
  filter(ModalPresent %in% c("yes")) %>%
  group_by(paraphrase,Question) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(agr, aes(x=mean_rating)) +
  geom_histogram() +
  facet_wrap(~paraphrase)


########################################################################
# NoModal
########################################################################
nomod = test_norm %>%
  filter(ModalPresent %in% c("no")) %>%
  group_by(paraphrase,Wh) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(nomod, aes(x=paraphrase,y=mean_rating,fill=Wh)) +
  geom_bar(stat="identity",position = "dodge") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9))

ggsave("../graphs/main_NoModalXWh.pdf")

ggplot(nomod, aes(x=mean_rating)) +
  geom_histogram() +
  facet_wrap(~Wh)

########################################################################
# Determiners
# TODO: go back to the database and make sure everything is coded properly
# Note Date: 12/2
########################################################################
nomod = test_norm %>%
  filter(ModalPresent %in% c("no") & paraphrase == "a" & DeterminerNonSubjPresent == "yes") %>%
# filter(grepl("a|the", DeterminerNonSubject)) %>%
group_by(DeterminerNonSubject) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)
ggplot(nomod, aes(x=DeterminerNonSubject,y=mean_rating,fill=DeterminerNonSubject)) +
  geom_bar(stat="identity",position = "dodge") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9))



head(test_norm)
agr = test_norm %>%
  group_by(paraphrase,Question) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(agr, aes(x=mean_rating)) +
  geom_histogram(stat="count") +
  facet_wrap(~paraphrase)
  # theme(legend.position = "none")



########################################################################
# Perusing items
########################################################################

the_high = test_norm %>%
  filter(paraphrase %in% c("the")) %>%
  group_by(tgrep_id,Question) %>%
  summarize(mean_rating = mean(rating)) %>%
  filter(mean_rating > .5)
View(the_high)

a_high = test_norm %>%
  filter(paraphrase %in% c("a")) %>%
  group_by(tgrep_id,Question) %>%
  summarize(mean_rating = mean(rating)) %>%
  filter(mean_rating > .3)
View(a_high)

ex = d %>%
  filter(tgrep_id %in% c("102025:30")) %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating))
View(ex)  

all_high = test_norm %>%
  filter(paraphrase %in% c("every")) %>%
  group_by(tgrep_id,Question) %>%
  summarize(mean_rating = mean(rating)) %>%
  filter(mean_rating > .4)
View(all_high)

other_high = test %>%
  filter(paraphrase %in% c("other")) %>%
  group_by(tgrep_id,Question) %>%
  summarize(mean_rating = mean(rating)) %>%
  filter(mean_rating > .5)
View(other_high)
  
########################################################################
########################################################################
# NORMING ROUND 2

# Paraphrase as predictor
# only "a" and "every" and "the"
########################################################################
critical = test_norm %>%
  filter(paraphrase %in% c("every","a","the"))
View(critical)

critical$ids = paste(critical$workerid,critical$tgrep_id)

critical$ModalPresent = as.factor(critical$ModalPresent)
critical$Wh = as.factor(critical$Wh)
critical$paraphrase = as.factor(critical$paraphrase)

# First renormalize the probability distribution to these three paraphrases
length(unique(critical$tgrep_id))
nrow(critical)

cr = critical %>%
  group_by(ids) %>%
  # summarize(rating_sum = rating[paraphrase=="a"] + rating[paraphrase=="every"] + rating[paraphrase=="the"])
  mutate(rating_a = rating[paraphrase=="a"], rating_every = rating[paraphrase=="every"], rating_the = rating[paraphrase=="the"]) %>%
  summarize(rating_sum = rating_a + rating_every + rating_the)
nrow(cr) #27585
# remove duplicate rows
xr = cr %>%
  distinct(ids, .keep_all=TRUE)
nrow(xr) #9195

nrow(xr)==length(unique(xr$ids))

critical = merge(xr,critical,by='ids')
nrow(critical) #27585
View(critical)

critical$factors = paste(critical$ids,critical$paraphrase)
normed_agr = critical %>%
  group_by(factors) %>%
  summarise(normed_rating = rating/rating_sum)
View(normed_agr)

normed = merge(normed_agr,critical,by='factors')
normed[is.na(normed$ModalPresent)] <- "no"

# save to .csv to load into analysis script
write.csv(normed,"../data/normed.csv")

nrow(normed)
View(normed)

agr = normed %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=ModalPresent)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  ggsave("../graphs/final_norm_ModxWh.pdf")


agr = normed %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position="dodge", show.legend = FALSE) +
  # ggtitle("Mean rating for 'a' vs. 'every'") +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  theme(legend.position = "none")
ggsave("../graphs/final_normed_overall.pdf")

########################################################################
########################################################################
# WH
########################################################################
########################################################################
agr = normed %>%
  group_by(paraphrase,Wh) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=Wh, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9))  +
  # ggtitle("Mean rating for Wh-Word") +
  xlab("Wh-Word") +
  ylab("Mean rating") +
  theme(legend.title = element_blank()) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal")
ggsave("../graphs/final_normed_wh.pdf")


########################################################################
########################################################################
# Modal
########################################################################
########################################################################
agr = normed %>%
  group_by(paraphrase,ModalPresent) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=ModalPresent, y=mean_rating, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  xlab("Modal Present") +
  ylab("Mean rating") +
  theme(legend.title = element_blank()) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal")
# legend.spacing.y = unit(-10, 'cm'))
# guides(fill=guide_legend(title="Paraphrase"))
ggsave("../graphs/final_normed_modalpresent.pdf")


mod = normed %>%
  filter(ModalPresent %in% c("yes")) %>%
  group_by(Modal,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(mod, aes(x=paraphrase,y=mean_rating,fill=paraphrase)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Modal)
ggsave("../graphs/final_normed_modals.pdf")



