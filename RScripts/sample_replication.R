## script de sampling des résultats pour évaluer 
## le nombre de réplication a faire pour ce modèole

library("dplyr")
library("ggplot2")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #def repertoire de travail

### avc du multi script

path <- "SamplingBasis/"
file.names <- list.files(paste0(path))

df <- data.frame()

for (i in 1:length(file.names)){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  df <- rbind(data.df, tmp)                                         ##ajout a data frame général, les données de tmp 
}


###

#df <- read.csv("../data/replication/BatchRunsForSampling.csv", header = FALSE, dec = ",") # dec pour les décimale

sample.v <- seq(from = 10, to = 100, by = 5) # vecteur du nombre de tirage

df.gp <- data.frame()
for(i in sample.v){
  for(j in 1:10){
    a <- df %>% slice_sample(n = i, replace = T) #tirage avec replication 
    a$gp <- j
    df.gp <- rbind(df.gp, a)
  }
  ggplot(data = df.gp)+
    geom_boxplot(aes(x = as.factor(gp), y = self.CThroughflow))+
    labs(x  = "sample", title = paste("nombre de réplication:", i))+
    #ylim(0.8,0.95)+ a fixer quand tu aura itentifier le range des Y pour facilité la lecture
    theme_bw()
  ggsave(paste0("../img/sample/sample",i,".png"))
}
