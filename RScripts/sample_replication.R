## script de sampling des résultats pour évaluer 
## le nombre de réplication a faire pour ce modèole

library("dplyr")
library("ggplot2")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #def repertoire de travail

df <- read.csv("../data/replication/BatchRunsForSampling.csv", header = FALSE, dec = ",") # dec pour les décimale

sample.v <- seq(from = 10, to = 100, by = 5) # vecteur du nombre de tirage

df.gp <- data.frame()
for(i in sample.v){
  for(j in 1:10){
    a <- df %>% slice_sample(n = i, replace = T)
    a$gp <- j
    df.gp <- rbind(df.gp, a)
  }
  ggplot(data = df.gp)+
    geom_boxplot(aes(x = as.factor(gp), y = V1))+
    labs(x  = "sample", title = paste("nombre de réplication:", i))+
    #ylim(0.8,0.95)+ a fixer quand tu aura itentifier le range des Y pour facilité la lecture
    theme_bw()
  ggsave(paste0("../img/sample/sample",i,".png"))
}
