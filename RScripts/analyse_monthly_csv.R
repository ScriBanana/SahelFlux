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

path <- "/"
file.names <- list.files(paste0(path))

file.names <- file.names[!is.na(stringr::str_extract(file.names, "\\d"))] ## filtre sur les fichier qui on un numero de mois

data.df <- data.frame()

for (i in 1:(length(file.names))){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  # Appliquer la soustraction de chaque ligne avec la valeur précédente
  tmp1 <- as.data.frame(lapply(tmp[,6:32], function(x) c(x[1], diff(x))))
  tmp <- cbind(tmp[,1:5],tmp1)
  tmp$run <- i      ## extraction du nombre depuis le nom du fichier
  data.df <- rbind(data.df, tmp)                                         ##ajout a data frame général, les données de tmp 
}


# saveRDS(data.df, "~/Téléchargements/runGama_arthur/bigDataFrame.rds") #sauvegarde dans un format compressé des données samplé
# truc <- readRDS("~/Téléchargements/runGama_arthur/bigDataFrame.rds")

# Calculer la moyenne par groupe
df_grouped <- data.df %>%
  group_by(current_date.month, current_date.year) %>%
  summarize(totalNFlows..kgN. = mean(totalNFlows..kgN.), 
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
            averageCroplandBiomass..kgC. = mean(averageCroplandBiomass..kgC.), 
            averageRangelandBiomass..kgC. = mean(averageRangelandBiomass..kgC.), 
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

df_grouped$date <- as.Date(paste(df_grouped$current_date.year, sprintf("%02d", df_grouped$current_date.month), "01", sep = "-"), format = "%Y-%m-%d")
df_grouped <- df_grouped[,-c(1:2)]

df_grouped_diff <- data.frame(
    diff(df_grouped$totalNFlows..kgN.),
    diff(df_grouped$totalNInflows..kgN.),
    diff(df_grouped$totalNThroughflows..kgN.),
    diff(df_grouped$totalNOutflows..kgN.),
    diff(df_grouped$totalCFlows..kgC.),
    diff(df_grouped$totalCInflows..kgC.),
    diff(df_grouped$totalCThroughflows..kgC.),
    diff(df_grouped$totalCOutflows..kgC.),
    diff(df_grouped$TSTN),
    diff(df_grouped$ICRN),
    diff(df_grouped$FinnN),
    diff(df_grouped$TSTC),
    diff(df_grouped$ICRC),
    diff(df_grouped$FinnC),
    diff(df_grouped$totalCO2..kgCO2.),
    diff(df_grouped$totalCH4..kgCH4.),
    diff(df_grouped$totalN2O..kgN2O.),
    diff(df_grouped$totalGHG..kgCO2eq.),
    diff(df_grouped$ecosystemCBalance),
    diff(df_grouped$ecosystemCO2Balance..kgCO2.),
    diff(df_grouped$ecosystemGHGBalance..kgCO2eq.),
    diff(df_grouped$SCS),
    diff(df_grouped$CFootprint),
    diff(df_grouped$averageCroplandBiomass..kgC.),
    diff(df_grouped$averageRangelandBiomass..kgC.),
    diff(df_grouped$meanHomefieldsSOCS..kgC.),
    diff(df_grouped$meanBushfieldsSOCS..kgC.),
    diff(df_grouped$meanRangelandSOCS..kgC.),
    diff(df_grouped$totalMeanSOCS..kgC.),
    diff(df_grouped$meanHomefieldsSOCSVariation..kgC.),
    diff(df_grouped$meanBushfieldsSOCSVariation..kgC.),
    diff(df_grouped$meanRangelandSOCSVariation..kgC.),
    diff(df_grouped$totalMeanSOCSVariation..kgC.)
  )
df_grouped_diff$date <- df_grouped$date[-1]

outFilesName <- "230710-Whole"

write.csv(df_grouped_diff, file=paste0(path, "/out/", outFilesName, ".csv"))

# Conversion du data frame en format long avec la fonction melt()
df_long <- melt(df_grouped_diff, id.vars = "date")
levels(df_long$variable) <- c(
    "totalNFlows (kgN)",
    "totalNInflows (kgN)",
    "totalNThroughflows (kgN)",
    "totalNOutflows (kgN)",
    "totalCFlows (kgC)",
    "totalCInflows (kgC)",
    "totalCThroughflows (kgC)",
    "totalCOutflows (kgC)",
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
    "ecosystemCBalance",
    "ecosystemCO2Balance (kgCO2)",
    "ecosystemGHGBalance (kgCO2eq)",
    "SCS",
    "CFootprint",
    "meanHomefieldsSOCSVariation (kgC)",
    "meanBushfieldsSOCSVariation (kgC)",
    "meanRangelandSOCSVariation (kgC)",
    "totalMeanSOCSVariation (kgC)"
  )

# Création du graphique en utilisant ggplot2 et facet_grid()
ggplot(df_long, aes(x = date, y = value, group = variable, color = variable)) +
  geom_line() +
  geom_smooth(span = 0.25)+
  facet_wrap(. ~ variable, scales = "free_y") +
  labs(title = "Moyenne de 10 réplications de 2020 à 2040")+
  theme_bw()+
  ylim(c(-38816740.21,24804845.397))+
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "none")

ggsave(paste0(path, "/out/", outFilesName, ".png"), height = 14, width = 18)
