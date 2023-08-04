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

path <- "../../../BackupSortiesSMA/230804-TestReset/"#Monthly/")
file.names <- list.files(path)

# file.names <- file.names[!is.na(stringr::str_extract(file.names, "\\d"))] ## filtre sur les fichier qui on un numero de mois

data.df <- data.frame()

for (i in 1:(length(file.names))){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  # Appliquer la soustraction de chaque ligne avec la valeur précédente
  # tmp1 <- as.data.frame(lapply(tmp[,6:40], function(x) c(x[1], diff(x))))
  # tmp <- cbind(tmp[,1:5],tmp1)
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
    ICRN = mean(ICRN),
    FinnN = mean(FinnN),
    TSTC = mean(TSTC),
    ICRC = mean(ICRC),
    FinnC = mean(FinnC),
    totalCO2..kgCO2. = mean(totalCO2..kgCO2.),
    totalCH4..kgCH4. = mean(totalCH4..kgCH4.),
    totalN2O..kgN2O. = mean(totalN2O..kgN2O.),
    totalGHG..kgCO2eq. = mean(totalGHG..kgCO2eq.),
    ecosystemCBalance = mean(ecosystemCBalance),
    ecosystemCO2Balance..kgCO2. = mean(ecosystemCO2Balance..kgCO2.),
    ecosystemGHGBalance..kgCO2eq. = mean(ecosystemGHGBalance..kgCO2eq.),
    SCS = mean(SCS),
    CFootprint = mean(CFootprint),
    nbTLUHerdsInArea = mean(nbTLUHerdsInArea),
    nbTLUFattened = mean(nbTLUFattened),
    herdsIntakeFlow = mean(herdsIntakeFlow),
    herdsExcretionsFlow = mean(herdsExcretionsFlow),
    totalHerdsIntakeFlow = mean(totalHerdsIntakeFlow),
    totalHerdsExcretionsFlow = mean(totalHerdsExcretionsFlow),
    averageCroplandBiomass..kgDM. = mean(averageCroplandBiomass..kgDM.),
    averageRangelandBiomass..kgDM. = mean(averageRangelandBiomass..kgDM.),
    meanHomefieldsSOCS..kgC. = mean(meanHomefieldsSOCS..kgC.),
    meanBushfieldsSOCS..kgC. = mean(meanBushfieldsSOCS..kgC.),
    meanRangelandSOCS..kgC. = mean(meanRangelandSOCS..kgC.),
    totalMeanSOCS..kgC. = mean(totalMeanSOCS..kgC.),
    meanHomefieldsSOCSVariation..kgC. = mean(meanHomefieldsSOCSVariation..kgC.),
    meanBushfieldsSOCSVariation..kgC. = mean(meanBushfieldsSOCSVariation..kgC.),
    meanRangelandSOCSVariation..kgC. = mean(meanRangelandSOCSVariation..kgC.),
    totalMeanSOCSVariation..kgC. = mean(totalMeanSOCSVariation..kgC.),
    .groups = 'drop'
    )

df_grouped$date <- as.Date(paste(df_grouped$Year, sprintf("%02d", df_grouped$Month), "01", sep = "-"), format = "%Y-%m-%d")
df_grouped <- df_grouped[,-c(1:2)]

outFilesName <- "Output"

write.csv(df_grouped, file=paste0(path, outFilesName, ".csv"))

# Conversion du data frame en format long avec la fonction melt()
df_long <- melt(df_grouped, id.vars = "date")
levels(df_long$variable) <- c(
    "totalNFlows (kgN)",
    "totalNInflows (kgN)",
    "totalNThroughflows (kgN)",
    "totalNOutflows (kgN)",
    "totalCFlows (kgC)",
    "totalCInflows (kgC)",
    "totalCThroughflows (kgC)",
    "totalCOutflows (kgC)",
    "TSTN",
    "ICRN",
    "FinnN",
    "TSTC",
    "ICRC",
    "FinnC",
    "totalCO2 (kgCO2)",
    "totalCH4 (kgCH4)",
    "totalN2O (kgN2O)",
    "totalGHG (kgCO2eq)",
    "ecosystemCBalance (kgC)",
    "ecosystemCO2Balance (kgCO2)",
    "ecosystemGHGBalance (kgCO2eq)",
    "SCS",
    "CFootprint",
    "nbTLUHerdsInArea",
    "nbTLUFattened",
    "herdsIntakeFlow (kgDM)",
    "herdsExcretionsFlow (kgDM VSE)",
    "totalHerdsIntakeFlow (kgDM)",
    "totalHerdsExcretionsFlow (kgDM VSE)",
    "averageCroplandBiomass (kgDM)",
    "averageRangelandBiomass (kgDM)",
    "meanHomefieldsSOCS (kgC)",
    "meanBushfieldsSOCS (kgC)",
    "meanRangelandSOCS (kgC)",
    "totalMeanSOCS (kgC)",
    "meanHomefieldsSOCSVariation (kgC)",
    "meanBushfieldsSOCSVariation (kgC)",
    "meanRangelandSOCSVariation (kgC)",
    "totalMeanSOCSVariation (kgC)"
  )

# Création du graphique en utilisant ggplot2 et facet_grid()
ggplot(df_long, aes(x = date, y = value, group = variable, color = variable)) +
  geom_line() +
  geom_smooth(span = 0.25) +
  facet_wrap(. ~ variable, scales = "free_y") +
  labs(title = "Moyenne de 52 réplications de 2020 à 2030") +
  theme_bw() +
  # ylim(c(-38816740.21,24804845.397)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "none")

ggsave(paste0(path, outFilesName, ".png"), height = 14, width = 18)

