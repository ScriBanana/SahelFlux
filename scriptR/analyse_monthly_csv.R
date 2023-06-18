# un script pour construire un data.frame a partir de fichier de simulation
# 1. on lit le contenu d'un dossier
# 2. on récupère l'identifiant du run
# 3. on le stcok dans un collonne
# 4. on le mets dans le data.frame final

library("dplyr")
library("ggplot2")
library("stringr")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #def repertoire de travail

path <- "~/Téléchargements/runGama_arthur/"
file.names <- list.files("~/Téléchargements/runGama_arthur/")

file.names <- file.names[!is.na(stringr::str_extract(file.names, "\\d"))] ## filtre sur les fichier qui on un numero de mois

data.df <- data.frame()

for (i in 1:length(file.names)){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  tmp$run <- as.numeric(stringr::str_extract(file.names[i], "\\d"))      ## extraction du nombre depuis le nom du fichier
  data.df <- rbind(data.df, tmp)                                         ##ajout a data frame général, les données de tmp 
}


saveRDS(data.df, "~/Téléchargements/runGama_arthur/bigDataFrame.rds") #sauvegarde dans un format compressé des données samplé
# truc <- readRDS("~/Téléchargements/runGama_arthur/bigDataFrame.rds")

