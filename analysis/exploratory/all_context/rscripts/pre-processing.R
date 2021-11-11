# ---
# title: "Analysis of ROOT & EMBEDDED QUESTIONS TOGETHER With CONTEXT"
# author: "mcmoyer"
# date: "March 30, 2021"
# ---

## Step 1: select stimuli for experiment
library(lme4)
library(lmerTest)
library(multcomp) # not available for this version of R
library(tidyverse)
theme_set(theme_bw())

this.dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(this.dir)

cbPalette <- c("#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73","#56B4E9", "#D55E00", "#009E73","#999999", "#E69F00","#009E73")

########################################################################
# Read the data into R.
rq = read.csv("../../../03_experiment/data/root_no_rhetorical.csv")
eq = read.csv("../../../04_experiment/data/embedded_no_rhetorical.csv")

rq = rq[,c("workerid","tgrep_id","ModalPresent","Modal","QuestionType","Question","Sentence","paraphrase","rating","Finite","Wh")]
eq = eq[,c("workerid","tgrep_id","ModalPresent","Modal","QuestionType","Question","Sentence","paraphrase","rating","Finite","Wh","VerbLemma")]

rq$QuestionType = "root"
rq$VerbLemma = ""

d = rbind(rq,eq)
# write.csv(d,"total_data.csv")

prop.table(table(eq$Wh,eq$ModalPresent))


d$ModalPresent = as.factor(d$ModalPresent)
d$Wh = as.factor(d$Wh)
d$paraphrase = as.factor(d$paraphrase)
d$QuestionType = as.factor(d$QuestionType)
d$VerbLemma = as.factor(d$VerbLemma)

# Set the reference levels
contrasts(d$paraphrase)
contrasts(d$Wh)

contrasts(d$Wh) = cbind("how.vs.when"=c(0,1,0,0,0,0),"what.vs.when"=c(1,0,0,0,0,0),
                "where.vs.when"=c(0,0,0,1,0,0),"who.vs.when"=c(0,0,0,0,1,0),
                "why.vs.when"=c(0,0,0,0,0,1))

# this won't work if the 'other' category is included, so REDO
contrasts(d$paraphrase) = cbind("a.vs.every"=c(1,0,0),"the.vs.every"=c(0,0,1))

centered = cbind(d,myCenter(d["ModalPresent"]))
centered = cbind(centered,myCenter(centered["QuestionType"]))

########################################################################
# GRAPHS
########################################################################
# OVERALL
agr = d %>%
  group_by(paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

dodge = position_dodge(.9)
ggplot(agr,aes(x=paraphrase, y=mean_rating, fill=paraphrase)) +
  geom_bar(position=dodge,stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=dodge, show.legend = FALSE) +
  # ggtitle("Mean rating for 'a' vs. 'every'") +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  ylim(0,.6) +
  theme(legend.position = "none") +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette)
ggsave("../graphs/overall.pdf",width=2,height=2)

########################################################################
# OVERALL QUESTION TYPE

sai = d %>%
  filter((QuestionType == "embeddedSAI")) %>% #  & (Wh == "why")
  group_by(tgrep_id,Sentence,VerbLemma,Question,paraphrase) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  filter(mean_rating > .5) %>%
  View()


agr = d %>%
  group_by(QuestionType,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

ggplot(agr,aes(x=paraphrase, y=mean_rating, alpha=QuestionType, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  # facet_grid(EmbeddedSQ~Wh) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  guides(fill=FALSE) +
  # guides(alpha=guide_legend(title="Embedded SAI")) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,-5,-5),legend.spacing.y = unit(0.001, 'cm')) +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette) +
  scale_alpha_discrete(range = c(.5,1))
ggsave("../graphs/overall_QT.pdf",width=3,height=3)

########################################################################
# OVERALL MOD x WH

agr = d %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

# Re-Order the WH-levels by overall composition of DB
agr$Wh <- factor(agr$Wh, levels=c("what","how","where","why","who","when"))

ggplot(agr,aes(x=paraphrase, y=mean_rating, alpha=ModalPresent, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh, ncol=2) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  guides(fill=FALSE) +
  guides(alpha=guide_legend(title="Modal present")) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,-5,-5),legend.spacing.y = unit(0.001, 'cm')) +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette) +
  scale_alpha_discrete(range = c(.5,1))

ggsave("../graphs/modxwh.pdf",width=3,height=4)


########################################################################
# OVERALL MOD x WH x QUESTIONTYPE
agr = d %>%
  group_by(QuestionType,Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

# Re-Order the WH-levels by overall composition of DB
agr$Wh <- factor(agr$Wh, levels=c("what","how","where","why","who","when"))

ggplot(agr,aes(x=paraphrase, y=mean_rating, alpha=ModalPresent, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_grid(QuestionType~Wh) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  # ggtitle("overall ratings for SAI in test qs") +
  guides(fill=FALSE) +
  guides(alpha=guide_legend(title="Modal present")) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,-5,-5),legend.spacing.y = unit(0.001, 'cm')) +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette) +
  scale_alpha_discrete(range = c(.5,1))
ggsave("../graphs/modxwh_QT.pdf",width=8,height=6)

########################################################################
# LOOKING AT verbs
########################################################################

verb_count = eq %>%
  group_by(VerbLemma) %>%
  summarize(count = n())
View(verb_count)

agr = eq %>%
  filter(VerbLemma == "know") %>%
  group_by(Wh,ModalPresent,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()

# Re-Order the WH-levels by overall composition of DB
agr$Wh <- factor(agr$Wh, levels=c("what","how","where","why","who","when"))

ggplot(agr,aes(x=paraphrase, y=mean_rating, alpha=ModalPresent, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Wh,ncol=2) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  guides(fill=FALSE) +
  guides(alpha=guide_legend(title="Modal present")) +
  ggtitle("know-wh") + 
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,-5,-5),legend.spacing.y = unit(0.001, 'cm')) +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette) +
  scale_alpha_discrete(range = c(.5,1))

ggsave("../graphs/modwh_know.pdf",width=3,height=4)


know = d %>%
  filter((paraphrase == "a") & (VerbLemma == "know")) %>%
  group_by(tgrep_id,Sentence) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

verb = d %>%
  filter((VerbLemma == "surprise")) %>%
  group_by(tgrep_id,Sentence,paraphrase) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

agr = eq %>%
  # Most frequent
  filter(VerbLemma %in% c("know","see","wonder","understand","be","tell","figure","say","think","sure","learn","remember")) %>%
  group_by(paraphrase,VerbLemma,ModalPresent) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh) %>%
  drop_na()


ggplot(agr,aes(x=paraphrase, y=mean_rating, alpha=ModalPresent, fill=paraphrase)) +
  geom_bar(position="dodge",stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax),width=.25,position=position_dodge(0.9)) +
  facet_wrap(~VerbLemma) +
  xlab("Paraphrase") +
  ylab("Mean rating") +
  guides(fill=FALSE) +
  guides(alpha=guide_legend(title="Modal present")) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal",
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,-5,-5),legend.spacing.y = unit(0.001, 'cm')) +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette) +
  scale_alpha_discrete(range = c(.5,1))

ggsave("../graphs/matrixverbs_frequent.pdf",width=6,height=5)


a_high = d %>%
  filter((paraphrase == "a")) %>% # & (VerbLemma == "doubt")
  group_by(tgrep_id,Sentence,VerbLemma,Question) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

every_high = d %>%
  filter((paraphrase == "every")) %>%
  group_by(tgrep_id,Sentence) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

the_high = d %>%
  filter((paraphrase == "the") & (VerbLemma == "know")) %>%
  group_by(tgrep_id,Sentence) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

ex = d %>%
  filter(tgrep_id == "75191:67") %>%
  select(Sentence,VerbLemma,Question,paraphrase,rating) %>%
  group_by(Sentence,Question,paraphrase) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()  

infinitival = d %>%
  filter((Finite == "no")) %>%
  group_by(tgrep_id,Sentence,paraphrase) %>%
  summarize(mean_rating = mean(rating), sd = sd(rating)) %>%
  View()

########################################################################
# LOOKING AT MODALS
########################################################################
# Recode nonfinite clauses as ModalPresent for graphs
d$ModalPresent[d$Finite == "no"] = "yes"
d$Modal[d$Finite == "no"] = "nonfinite"
# Recode contracted Modals
d$Modal[d$Modal == "ca"] = "can"
d$Modal[d$Modal == "'ll"] = "will"
d$Modal[d$Modal == "'d"] = "could"

agr = d %>%   
  filter(ModalPresent %in% c("yes")) %>%
  group_by(Modal,paraphrase) %>%
  summarize(mean_rating = mean(rating), CILow = ci.low(rating), CIHigh = ci.high(rating)) %>%
  mutate(YMin = mean_rating - CILow, YMax = mean_rating + CIHigh)

ggplot(agr, aes(x=paraphrase,y=mean_rating,fill=paraphrase)) +
  geom_bar(stat="identity") +
  geom_errorbar(aes(ymin=YMin,ymax=YMax), width=.25,position=position_dodge(0.9)) +
  facet_wrap(~Modal,ncol=5) +
  theme(legend.title = element_blank()) +
  theme(legend.key.size = unit(0.3, "cm"),
        legend.position = "top", # c(.5,1)
        legend.direction = "horizontal") +
  scale_fill_manual(values=cbPalette) +
  scale_color_manual(values=cbPalette)
ggsave("../graphs/modals.pdf",,width=5,height=3)

########################################################################
########################################################################
########################################################################
# definite and indefinite
# Read database
corp = read.table("../../corpus/results/swbd.tab",sep="\t",header=T,quote="")
names(corp)[names(corp) == "Item_ID"] <- "tgrep_id"
# join dfs together
d <- left_join(d, corp_match, by="tgrep_id")

d$DeterminerSubject = as.factor(d$DeterminerSubject)
d$DeterminerSubjPresent = as.factor(d$DeterminerSubjPresent)
str(d$DeterminerSubjPresent)
d$DeterminerNonSubject = as.factor(d$DeterminerNonSubject)
d$DeterminerNonSubjPresent = as.factor(d$DeterminerNonSubjPresent)
names(d)
det_sbj = d %>%
  filter(DeterminerSubjPresent != "no")
View(det_sbj)

str(d$DeterminerSubjPresent)

det_non_sbj = d %>%
  filter(DeterminerNonSubjPresent == "no")
