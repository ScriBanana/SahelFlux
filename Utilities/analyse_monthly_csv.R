# un script pour construire un data.frame a partir de fichier de simulation
# 1. on lit le contenu d'un dossier
# 2. on récupère l'identifiant du run
# 3. on le stcok dans un collonne
# 4. on le mets dans le data.frame final

library("dplyr")
library("ggplot2")
library("stringr")
library("reshape2")

rm(list = ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #def repertoire de travail

## PARAMETERS
vilName <- "Barry"
dir <- "/home/scriban/Dropbox/Thèse/DonneesEtSauvegardes/BackupSortiesSMA/230904-LongRun/Monthly/"
nbRep <- 8
runLength <- 10 # years
##

path <- paste0(dir, vilName, "/")
file.names <- list.files(path)

file.names <- file.names[!is.na(stringr::str_extract(file.names, "\\d"))] ## filtre sur les fichier qui on un numero de mois

data.df <- data.frame()

for (i in 1:(length(file.names))){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  # Appliquer la soustraction de chaque ligne avec la valeur précédente
  tmp1 <- as.data.frame(lapply(tmp[,6:49], function(x) c(x[1], diff(x))))
  tmp <- cbind(tmp[,1:5],tmp1)
  tmp$run <- i      ## extraction du nombre depuis le nom du fichier
  data.df <- rbind(data.df, tmp)                                         ##ajout a data frame général, les données de tmp 
}


# saveRDS(data.df, "~/Téléchargements/runGama_arthur/bigDataFrame.rds") #sauvegarde dans un format compressé des données samplé
# truc <- readRDS("~/Téléchargements/runGama_arthur/bigDataFrame.rds")

# Calculer la moyenne par groupe
df_grouped <- data.df %>%
  group_by(Month, Year) %>%
  summarize(
    totalNFlows..kgN. = mean(totalNFlows..kgN.),
    totalNInflows..kgN. = mean(totalNInflows..kgN.),
    totalNThroughflows..kgN. = mean(totalNThroughflows..kgN.),
    totalNOutflows..kgN. = mean(totalNOutflows..kgN.),
    totalCFlows..kgC. = mean(totalCFlows..kgC.),
    totalCInflows..kgC. = mean(totalCInflows..kgC.),
    totalCThroughflows..kgC. = mean(totalCThroughflows..kgC.),
    totalCOutflows..kgC. = mean(totalCOutflows..kgC.),
    TSTN = mean(TSTN),
    pathLengthN = mean(pathLengthN),
    ICRN = mean(ICRN),
    TSTC = mean(TSTC),
    pathLengthC = mean(pathLengthC),
    ICRC = mean(ICRC),
    totalCO2..kgCO2. = mean(totalCO2..kgCO2.),
    totalCH4..kgCH4. = mean(totalCH4..kgCH4.),
    totalN2O..kgN2O. = mean(totalN2O..kgN2O.),
    totalGHG..kgCO2eq. = mean(totalGHG..kgCO2eq.),
    ecosystemCBalance = mean(ecosystemCBalance),
    ecosystemNBalance = mean(ecosystemNBalance),
    ecosystemApparentCBalance = mean(ecosystemApparentCBalance),
    ecosystemApparentNBalance = mean(ecosystemApparentNBalance),
    ecosystemCO2Balance..kgCO2. = mean(ecosystemCO2Balance..kgCO2.),
    ecosystemGHGBalance..kgCO2eq. = mean(ecosystemGHGBalance..kgCO2eq.),
    CFootprint = mean(CFootprint),
    nbTLUHerdsInArea = mean(nbTLUHerdsInArea),
    nbTLUFattened = mean(nbTLUFattened),
    herdsIntakeFlow..kgDM. = mean(herdsIntakeFlow..kgDM.),
    fattenedIntakeFlow..kgDM. = mean(fattenedIntakeFlow..kgDM.),
    herdsExcretionsFlow..kgDM. = mean(herdsExcretionsFlow..kgDM.),
    fattenedExcretionsFlow..kgDM. = mean(fattenedExcretionsFlow..kgDM.),
    complementsInflow..kgDM. = mean(complementsInflow..kgDM.),
    averageCroplandBiomass..kgDM. = mean(averageCroplandBiomass..kgDM.),
    averageRangelandBiomass..kgDM. = mean(averageRangelandBiomass..kgDM.),
    meanHomefieldsSOCS..kgC. = mean(meanHomefieldsSOCS..kgC.),
    meanBushfieldsSOCS..kgC. = mean(meanBushfieldsSOCS..kgC.),
    meanRangelandSOCS..kgC. = mean(meanRangelandSOCS..kgC.),
    totalMeanSOCS..kgC. = mean(totalMeanSOCS..kgC.),
    homefieldsSOCMoran = mean(homefieldsSOCMoran),
    bushfieldsSOCMoran = mean(bushfieldsSOCMoran),
    croplandSOCMoran = mean(croplandSOCMoran),
    rangelandSOCMoran = mean(rangelandSOCMoran),
    globalSOCMoran = mean(globalSOCMoran),
    .groups = 'drop'
    )

df_grouped$date <- as.Date(paste(
  df_grouped$Year, sprintf("%02d", df_grouped$Month), "01", sep = "-"), format = "%Y-%m-%d")
df_grouped <- df_grouped[,-c(1:2)]

outFilesName <- paste0(vilName, "Output")

write.csv(df_grouped, file=paste0(path, "/", outFilesName, ".csv"))

# Conversion du data frame en format long avec la fonction melt()
df_long <- melt(df_grouped, id.vars = "date")
levels(df_long$variable) <- c(
  "totalNFlows..kgN.",
  "totalNInflows..kgN.",
  "totalNThroughflows..kgN.",
  "totalNOutflows..kgN.",
  "totalCFlows..kgC.",
  "totalCInflows..kgC.",
  "totalCThroughflows..kgC.",
  "totalCOutflows..kgC.",
  "TSTN",
  "pathLengthN",
  "ICRN",
  "TSTC",
  "pathLengthC",
  "ICRC",
  "totalCO2..kgCO2.",
  "totalCH4..kgCH4.",
  "totalN2O..kgN2O.",
  "totalGHG..kgCO2eq.",
  "ecosystemCBalance",
  "ecosystemNBalance",
  "ecosystemApparentCBalance",
  "ecosystemApparentNBalance",
  "ecosystemCO2Balance..kgCO2.",
  "ecosystemGHGBalance..kgCO2eq.",
  "CFootprint",
  "nbTLUHerdsInArea",
  "nbTLUFattened",
  "herdsIntakeFlow..kgDM.",
  "fattenedIntakeFlow..kgDM.",
  "herdsExcretionsFlow..kgDM.",
  "fattenedExcretionsFlow..kgDM.",
  "complementsInflow..kgDM.",
  "averageCroplandBiomass..kgDM.",
  "averageRangelandBiomass..kgDM.",
  "meanHomefieldsSOCS..kgC.",
  "meanBushfieldsSOCS..kgC.",
  "meanRangelandSOCS..kgC.",
  "totalMeanSOCS..kgC.",
  "homefieldsSOCMoran",
  "bushfieldsSOCMoran",
  "croplandSOCMoran",
  "rangelandSOCMoran",
  "globalSOCMoran"
)

# Création du graphique en utilisant ggplot2 et facet_grid()
ggplot(df_long, aes(x = date, y = value, group = variable, color = variable)) +
  geom_line() +
#  geom_smooth(span = 0.25) +
  facet_wrap(. ~ variable, scales = "free_y") +
  labs(title = paste0(vilName, " - ", runLength, " years - ", nbRep, " replications")) +
  theme_bw() +
  # ylim(c(-38816740.21,24804845.397)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "none")

ggsave(paste0(path, outFilesName, ".png"), height = 10, width = 18)

